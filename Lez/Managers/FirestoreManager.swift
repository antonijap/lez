//
//  FirestoreManager.swift
//  Lez
//
//  Created by Antonija on 01/04/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Foundation
import Firebase
import Promises

class FirestoreManager {
    
    let db = Firestore.firestore()
    static let sharedInstance = FirestoreManager()
    
    func createUser() {
        
    }
    
    func addUser(uid: String, data: [String: Any]) -> Promise<Bool> {
        return Promise { fulfill, reject in
            self.db.collection("users").document(uid).setData(data) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                    reject(err)
                } else {
                    print("Document successfully updated")
                    fulfill(true)
                }
            }
        }
    }
    
    func uploadImage(user: User, data: Data, reference: StorageReference) -> Promise<String> {
        return Promise { fulfill, reject in
            reference.putData(data, metadata: nil) { (metadata, error) in
                if let error = error {
                    reject(error)
                }
                guard let url = metadata?.downloadURLs?.first?.absoluteString else { return }
                fulfill(url)
            }
        }
    }
    
    func fetchPotentialMatches() {
        
    }
}
