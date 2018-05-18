//
//  PusherManager.swift
//  Lez
//
//  Created by Antonija Pek on 15/05/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Foundation
import PusherSwift
import SwiftyJSON

class PusherManager {
    
    static let shared = PusherManager()
    private var pusher: Pusher!
    private var channel: PusherChannel?
    
    private init() {
        connect()
    }
    
    private func connect() {
        let options = PusherClientOptions(
            host: .cluster("eu")
        )
        pusher = Pusher(key: "b5bd116d3da803ac6d12", options: options)
        pusher.connect()
    }
    
    func subscribe(to uid: String) {
        channel = pusher.subscribe(uid)
        
    }
    
    func trigger(data: [String: Any]) {
        channel?.trigger(eventName: "new_message", data: data)
    }
    
    func listen(for event: String) {
        guard let channel = channel else { return }
        let _ = channel.bind(eventName: event, callback: { (data: Any?) -> Void in
            if let data = data as? [String : AnyObject] {
                if let message = data["message"] as? String {
                    print(message)
                }
            }
        })
    }
    
}
