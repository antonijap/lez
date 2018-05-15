//
//  ChatManager.swift
//  Lez
//
//  Created by Antonija Pek on 15/05/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Foundation
import Firebase

final class ChatManager {
    
    let db = Firestore.firestore()
    static let shared = ChatManager()
    
    var lastUpdated: Date?
    
    func observeChangesInChats(for uid: String, completion: @escaping () -> Void) {
        db.collection("chats").whereField("participants.\(uid)", isEqualTo: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching documents: \(error!)")
                    return
                }
                for document in documents {
                    let data = document.data()
                    
                    guard let newlastUpdated = data["lastUpdated"] as? String else {
                        print("Problem with parsing lastUpdated.")
                        return
                    }
                    let date = newlastUpdated.date(format: .custom("yyyy-MM-dd HH:mm:ss"))?.absoluteDate
                }
        }
    }
    
//    func observeIfNewCJelhat(for uid: String, completion: @escaping () -> Void) {
//        Firestore.firestore().collection("users").document(uid)
//            .addSnapshotListener { document, error in
//                guard let document = quersnapshotySnapshot?.data() else {
//                    print("Error fetching documents: \(error!)")
//                    return
//                }
//                completion()
//        }
//    }
}


