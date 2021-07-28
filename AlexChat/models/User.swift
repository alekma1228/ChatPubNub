//
//  User.swift
//  AlexChat
//
//  Created by Alex Lee on 6/10/21.
//  Copyright © 2021 Alex Lee. All rights reserved.
//

import UIKit

struct User: Codable, Hashable {
    private static let senderStorageKey = "DefaultedSender"

    var uuid: String
    var name: String
}

extension User {
    public var displayName: String {
        return name
    }

    var isCurrentUser: Bool {
        return User.defaultValue == self
    }
}

extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}

extension User: Defaultable {
    static var defaultValue: User {
        if let sender = User.retrieve(from: .userDefaults, with: senderStorageKey) {
            return sender
        }

        let sender = User.defaultValues[Int.random(in: 0..<User.defaultValues.count)]
        sender.store(in: .userDefaults, at: senderStorageKey)

        return sender
    }

    static var defaultValues: [User] {
        return  [
            User(uuid: "user-1", name: "user1"),
            User(uuid: "user-2", name: "user2"),
            User(uuid: "user-3", name: "user3"),
            User(uuid: "user-4", name: "user4"),
            User(uuid: "user-5", name: "user5"),
        ]
    }
}
