//
//  ChatViewModel.swift
//  AlexChat
//
//  Created by Alex Lee on 6/10/21.
//  Copyright © 2021 Alex Lee. All rights reserved.
//

import Foundation

struct ChatViewModel {
    enum ChangeType {
        case messages
        case occupancy
        case connected(Bool)
    }
    
    typealias Listener = (ChangeType) -> Void
    var listener: Listener?

    private var appStateService: AppStateService
    private var chatService: ChatRoomService

    init(with chatService: ChatRoomService, appStateService: AppStateService = AppStateService()) {
        self.chatService = chatService
        self.appStateService = appStateService
    }
    private var chatListener: ChatRoomService.Listener {
        return { (chatEvent) in
            switch chatEvent {
            case .messages:
                self.listener?(.messages)
            case .presence:
                self.listener?(.occupancy)
            case .status(let event):
                switch event {
                case .success(let statusEvent):
                    switch statusEvent {
                    case .connected:
                        self.chatService.fetchMessageHistory()
                        self.chatService.fetchCurrentUsers()
                        self.listener?(.connected(true))
                    case .notConnected:
                        self.listener?(.connected(false))
                    }
                case .failure:
                    break
                }
            }
        }
    }
    private var appStateListener: AppStateService.Listener {
        return { (appState) in
            switch appState {
            case .didBecomeActive:
                if self.chatService.state == .notConnected {
                    self.chatService.start()
                } else {
                    self.chatService.fetchMessageHistory()
                    self.chatService.fetchCurrentUsers()
                }
            case .willResignActive:
                self.chatService.stop()
            case .didEnterBackground, .willEnterForeground:
                break
            }
        }
    }
    func bind() {
        appStateService.listener = appStateListener
        appStateService.start()

        chatService.listener = chatListener
        chatService.start()
    }
        var sender: User? {
        return chatService.sender
    }
    var chatRoom: ChatRoom {
        return chatService.room
    }
    var messages: [Message] {
        return chatService.messages
    }
    func send(_ message: String, completion: @escaping (Result<Message, NSError>) -> Void) {
        _ = chatService.send(message) { (result) in
            completion(result)
        }
    }
}
