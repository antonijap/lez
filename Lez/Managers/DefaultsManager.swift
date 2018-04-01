//
//  DefaultsManager.swift
//  Lez
//
//  Created by Antonija on 31/03/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Foundation

class DefaultsManager {
    
    static let sharedInstance = DefaultsManager()
    
    let defaults = UserDefaults.standard
    
    func saveUser(user: User) {
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: user)
        defaults.set(encodedData, forKey: "user")
        defaults.synchronize()
    }
    
    func fetchCurrentUser() -> User? {
        let user = defaults.object(forKey: "user") as? User
        return user
    }
    
    func isCurrentUserOnboarded() -> Bool {
        if let user = fetchCurrentUser() {
            if user.isOnboarded {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
}
