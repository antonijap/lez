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
    var created: Timestamp
    var from: String
    var message: String
}

class Chat {
    var uid: String
    var created: Timestamp
    var lastUpdated: Timestamp
    var participants: [User]
    var messages: [Message]?
    var isRead: Bool
    
    init(uid: String, created: Timestamp, lastUpdated: Timestamp, participants: [User], messages: [Message]?, isRead: Bool) {
        self.uid = uid
        self.created = created
        self.lastUpdated = lastUpdated
        self.participants = participants
        self.messages = messages
        self.isRead = isRead
    }
}
