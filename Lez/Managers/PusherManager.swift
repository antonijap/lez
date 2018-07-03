//
//  ChatManager.swift
//  Lez
//
//  Created by Antonija Pek on 15/05/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Foundation
import PusherSwift
import Alamofire

enum Events: String {
    case newMessage = "new-message"
}

final class PusherManager {

    static let shared = PusherManager()
    private let options = PusherClientOptions(host: .cluster("eu"))
    private var pusher: Pusher
    private var channel: PusherChannel

    private init() {
        pusher  = Pusher(withAppKey: "b5bd116d3da803ac6d12", options: options)
        channel = PusherChannel(name: "defaultPusherChannel", connection: pusher.connection)
    }

    private func setupPusher() {
    }

    func subscribe(to name: String) {
        channel = pusher.subscribe(name)
    }

    func listen(name: String, completion: @escaping () -> Void) {
        channel.bind(eventName: name, callback: { (data: Any?) -> Void in
            if let data = data as? [String : AnyObject] {
                if let message = data["message"] as? String { print(message); completion() }
            }
        })
        pusher.connect()
    }

    func trigger(channel: String, event: Events) {
        let parameters: Parameters = ["channel": channel, "event": event.rawValue]
        Alamofire.request("https://us-central1-lesbian-dating-app.cloudfunctions.net/triggerPusherChannel",
                          parameters: parameters, encoding: URLEncoding.default)
    }
    
}
