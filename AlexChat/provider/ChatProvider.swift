//
//  ChatProvider.swift
//  AlexChat
//
//  Created by Alex Lee on 6/10/21.
//  Copyright © 2021 Alex Lee. All rights reserved.
//

import Foundation

class ChatEventProvider: NSObject {
    enum ChatEvent {
        case message(ChatMessageEvent)
        case presence(ChatPresenceEvent)
        case status(Result<ChatStatusEvent, NSError>)
    }

    typealias Listener = (ChatEvent) -> Void

    var listener: Listener?

    static let `default` = ChatEventProvider()

    private override init() {
        super.init()
    }
}

protocol ChatProvider {
    func send(_ request: ChatMessageRequest, completion: @escaping  (Result<ChatMessageResponse, NSError>) -> Void)
    func history(_ request: ChatHistoryRequest, completion: @escaping  (Result<ChatHistoryResponse?, NSError>) -> Void)
    func presence(for roomId: String, completion: @escaping  (Result<ChatRoomPresenceResponse?, NSError>) -> Void)
    var senderID: String { get }
    var eventEmitter: ChatEventProvider { get }
    func subscribe(to roomId: String)
    func unsubscribe(from roomId: String)
    func isSubscribed(on roomId: String) -> Bool
}

struct ChatMessageRequest {
    var roomId: String
    var message: [String: String]
    var parameters: ChatPublishParameters

    init(roomId: String, message: Message, parameters: ChatPublishParameters = ChatPublishParameters()) {
        self.message = ["senderId": message.senderId, "text": message.text, "uuid": message.uuid]
        self.roomId = roomId
        self.parameters = ChatPublishParameters()
    }
}

struct ChatPublishParameters {
    var metadata: [String: Any]?
    var compressed: Bool = false
    var storeInHistory: Bool = true
    var mobilePushPayload: [String: Any]?
}

protocol ChatMessageResponse {
    var sentAt: Int64 { get }
    var responseMessage: String { get }
}

struct ChatHistoryRequest {
    var roomId: String
    var parameters: ChatHistoryParameters

    init(roomId: String, parameters: ChatHistoryParameters = ChatHistoryParameters()) {
        self.roomId = roomId
        self.parameters = parameters
    }
}

struct ChatHistoryParameters {
    var start: Int64?
    var limit: UInt = 100
    var reverse: Bool = false
    var includeTimeToken: Bool = true
}

protocol ChatHistoryResponse {
    var start: Int64 { get }
    var end: Int64 { get }
    var messages: [Message] { get }
}

protocol ChatRoomPresenceResponse {
    var occupancy: Int { get }
    var uuids: [String] { get }
}

protocol ChatMessageEvent {
    var roomId: String { get }
    var message: Message? { get }
}

protocol ChatPresenceEvent {
    var roomId: String { get }
    var occupancy: Int { get }
    var joined: [String] { get }
    var timedout: [String] { get }
    var left: [String] { get }
}

enum StatusResponse: String {
    case acknowledgment
    case connected
    case reconnected
    case disconnected
    case cancelled

    case error
}

enum RequestType: String {
    case subscribe
    case unsubscribe

    case send
    case history
    case presence

    case other
}

protocol ChatStatusEvent {
    var response: StatusResponse { get }
    var request: RequestType { get }
}
