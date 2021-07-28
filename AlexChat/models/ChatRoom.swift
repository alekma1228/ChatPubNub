//
//  ChatRoom.swift
//  AlexChat
//
//  Created by Alex Lee on 6/10/21.
//  Copyright © 2021 Alex Lee. All rights reserved.
//

import UIKit

struct ChatRoom: Codable, Hashable {
    var uuid: String
    var name: String
    var description: String?
    var avatarName: String?
}

extension ChatRoom {
    var avatar: UIImage? {
        guard let image = avatarName else {
            return nil
        }

        return UIImage(named: image)
    }
}

extension ChatRoom: Defaultable {
    static var defaultValue: ChatRoom {
        return ChatRoom(uuid: "demo",
                    name: "Demo",
                    description: "Chat.",
                    avatarName: "Test")
    }
}
