//
//  Message.swift
//  AlexChat
//
//  Created by Alex Lee on 6/10/21.
//  Copyright © 2021 Alex Lee. All rights reserved.
//

import Foundation

struct Message: Codable, Hashable {
    var uuid: String
    var text: String
    var sentAt: Int64
    var senderId: String
    var roomId: String
}

extension Message {
    var user: User? {
        return  User.firstStored(with: { $0.uuid == senderId })
    }
    var room: ChatRoom? {
        return ChatRoom.firstStored(with: { $0.uuid == roomId })
    }
    var sentDate: Date {
        return Date(timeIntervalSince1970: TimeInterval(integerLiteral: sentAtInSeconds))
    }
    var sentAtInSeconds: Int64 {
        return sentAt/10000000
    }
}

extension Message: Equatable {
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}
