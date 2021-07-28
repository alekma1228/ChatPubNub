//
//  ChatRoomService.swift
//  AlexChat
//
//  Created by Alex Lee on 6/10/21.
//  Copyright © 2021 Alex Lee. All rights reserved.
//

import Foundation
import PubNub

class ChatRoomService {
    typealias PresenceChange = (joined: [String], left: [String])

    enum ConnectionState {
        case connected
        case notConnected
    }

    enum ChatRoomEvent {
        case messages(Result<[Message], NSError>)
        case presence(Result<PresenceChange, NSError>)
        case status(Result<ConnectionState, NSError>)
    }

    typealias Listener = (ChatRoomEvent) -> Void

    var listener: Listener?
    private(set) var room: ChatRoom

    private var chatProvider: ChatProvider

    private var _occupantUUIDs = Set<String>()
    private var _messages = [Message]()

    private let presenceQueue = DispatchQueue(label: "ChatRoomService Presence Queue",
                                            qos: .userInitiated, attributes: .concurrent)
    private let messageQueue = DispatchQueue(label: "ChatRoomService Message Queue",
                                           qos: .userInitiated, attributes: .concurrent)
    private let eventQueue = DispatchQueue(label: "ChatRoomService Event Queue")

    private let historyRequestQueue = DispatchQueue(label: "ChatRoomService History Request Queue")
    private let historyRequestGroup = DispatchGroup()
    
    init(for chatRoom: ChatRoom = ChatRoom.defaultValue, with provider: ChatProvider = PubNub.configure()) {
        self.room = chatRoom
        self.chatProvider = provider

        self.chatProvider.eventEmitter.listener = { [weak self] (event) in
            switch event {
            case .message(let message):
                self?.didReceive(message: message)
            case .presence(let event):
                self?.didReceive(presence: event)
            case .status(let result):
                self?.didReceive(status: result)
            }
        }
    }

    deinit {
        chatProvider.unsubscribe(from: room.uuid)
    }

    var occupantUUIDs: [String] {
        var users = Set<String>()
        presenceQueue.sync {
            users = self._occupantUUIDs
        }

        return Array(users)
    }

    var messages: [Message] {
        var messages = [Message]()

        messageQueue.sync {
            messages = self._messages
        }
        return messages
    }

    var occupancy: Int {
        return occupantUUIDs.count
    }

    var latestSentAt: Int64? {
        return messages.last?.sentAt
    }

    var state: ConnectionState {
        return chatProvider.isSubscribed(on: room.uuid) ? .connected : .notConnected
    }

    var sender: User? {
        return User.firstStored(with: { $0.uuid == chatProvider.senderID })
    }

  // MARK: - Service Stop/Start
    func start() {
        if !chatProvider.isSubscribed(on: room.uuid) {
            chatProvider.subscribe(to: room.uuid)
        }
    }

    func stop() {
        chatProvider.unsubscribe(from: room.uuid)
    }

  // MARK: - Public Methods
    func send(_ text: String, completion: @escaping (Result<Message, NSError>) -> Void) {
        let sentAtValue = Date().timeIntervalAsImpreciseToken
        let message = Message(uuid: UUID().uuidString,
                          text: text,
                          sentAt: sentAtValue,
                          senderId: chatProvider.senderID,
                          roomId: room.uuid)

        let request = ChatMessageRequest(roomId: room.uuid, message: message)

        self.chatProvider.send(request) { (result) in
            switch result {
            case .success:
                completion(.success(message))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    func fetchMessageHistory() {
        let roomID = room.uuid
        historyRequestQueue.async { [weak self] in
            self?.historyRequestGroup.enter()

            var params = ChatHistoryParameters()
            if let sentAtValue = self?.latestSentAt {
                params.start = sentAtValue
                params.reverse = true
            }

            let historyRequest = ChatHistoryRequest(roomId: roomID, parameters: params)

            self?.chatProvider.history(historyRequest) { [weak self] (result) in
                switch result {
                case .success(let response):
                    guard let response = response else {
                        self?.emit(.messages(.success([])))
                        return
                    }
                    self?.add(response.messages)
                case .failure(let error):
                    self?.emit(.messages(.failure(error)))
                }
                self?.historyRequestGroup.leave()
            }
            self?.historyRequestGroup.wait()
        }
    }
    func fetchCurrentUsers() {
        let roomID = room.uuid

        self.chatProvider.presence(for: roomID) { [weak self] (result) in
            switch result {
            case .success(let response):
                guard let response = response else {
                    self?.emit(.presence(.success(([], []))))
                    return
                }
                self?.presenceQueue.async(flags: .barrier) { [weak self] in
                    var joinedList = [String]()
                    for uuid in response.uuids {
                        let value = self?._occupantUUIDs.insert(uuid)
                        if let wasAdded = value?.inserted, wasAdded {
                            joinedList.append(uuid)
                        }
                    }
                    self?.emit(.presence(.success((joinedList, []))))
                }

            case .failure(let error):
                self?.emit(.presence(.failure(error)))
            }
        }
    }
    // MARK: Event Listeners
    private func didReceive(message response: ChatMessageEvent) {
        guard let message = response.message else {
            return
        }
        self.add([message])
    }

    private func didReceive(status event: Result<ChatStatusEvent, NSError>) {
        switch event {
        case .success(let status):
            switch status.response {
            case .connected, .reconnected:
                presenceQueue.async(flags: .barrier) { [weak self] in
                    if let senderID = self?.chatProvider.senderID {
                        self?._occupantUUIDs.insert(senderID)
                    }
                    self?.emit(.status(.success(.connected)))
                }
            case .disconnected:
                presenceQueue.async(flags: .barrier) { [weak self] in
                    self?._occupantUUIDs.removeAll()
                    self?.emit(.status(.success(.notConnected)))
                }
            default:
                NSLog("Category \(status.response) was not processed.")
            }
        case .failure(let error):
            emit(.status(.failure(error)))
        }
    }

    private func didReceive(presence response: ChatPresenceEvent) {
        presenceQueue.async(flags: .barrier) { [weak self] in
            for uuid in response.joined {
                self?._occupantUUIDs.insert(uuid)
            }
            for uuid in response.timedout {
                self?._occupantUUIDs.remove(uuid)
            }
            for uuid in response.left {
                self?._occupantUUIDs.remove(uuid)
            }

            self?.emit(.presence(.success((response.joined, response.timedout+response.left))))
        }
    }

    // MARK: - Private Methods
    private func emit(_ event: ChatRoomEvent) {
        eventQueue.async { [weak self] in
            self?.listener?(event)
        }
    }

    private func add(_ messages: [Message]) {
        messageQueue.async(flags: .barrier) { [weak self] in
            for message in messages {
                if self?._messages.contains(message) ?? true {
                    continue
                }
                self?._messages.append(message)
            }
            self?._messages.sort(by: { $0.sentAt < $1.sentAt })
            self?.emit(.messages(.success(messages)))
        }
    }
}

