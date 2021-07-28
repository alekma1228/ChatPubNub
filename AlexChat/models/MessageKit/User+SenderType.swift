//
//  User+SenderType.swift
//  AlexChat
//
//  Created by Alex Lee on 6/10/21.
//  Copyright © 2021 Alex Lee. All rights reserved.
//

import MessageKit

extension User: SenderType {
    var initials: String {
        return name
    }
    public var senderId: String {
        return uuid
    }
}
