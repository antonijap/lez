//
//  Chat.swift
//  Lez
//
//  Created by Antonija on 28/04/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Foundation
import Firebase

struct Message {
    var created: String
    var from: String
    var message: String
}

final class Chat {
    var uid: String
    var created: String
    var lastUpdated: String
    var participants: [User]
    var messages: [Message]?
    var isDisabled: Bool

    init(uid: String, created: String, lastUpdated: String, participants: [User], messages: [Message]?, isDisabled: Bool) {
        self.uid = uid
        self.created = created
        self.lastUpdated = lastUpdated
        self.participants = participants
        self.messages = messages
        self.isDisabled = isDisabled
    }
}
