//
//  Message+MessageType.swift
//  AlexChat
//
//  Created by Alex Lee on 6/10/21.
//  Copyright © 2021 Alex Lee. All rights reserved.
//

import MessageKit

extension Message: MessageType {
    var messageId: String {
        return uuid
    }

    var sender: SenderType {
        return user ?? User.defaultValue
    }

    var kind: MessageKind {
        return .text(self.text)
    }
}
