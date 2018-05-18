//
//  ChatManager.swift
//  Lez
//
//  Created by Antonija Pek on 15/05/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Foundation
import Firebase
import UIKit

final class ChatManager {
    
    let db = Firestore.firestore()
    static let shared = ChatManager()
    
    func listenForNewChats(user: String, completion: @escaping (_ number: Int) -> Void) {
        db.collection("users").document(user).addSnapshotListener { snapshot, error in
            guard let data = snapshot?.data() else {
                print("Error fetching documents: \(error!)")
                return
            }
            guard let chats = data["chats"] as? [String] else {
                print("Problem with parsing isOnboarded.")
                return
            }
            let number = chats.count
            completion(number)
        }
    }
}


