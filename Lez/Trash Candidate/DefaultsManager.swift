//
//  DefaultsManager.swift
//  Lez
//
//  Created by Antonija on 31/03/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Foundation

final class DefaultsManager {
    
    private init() { }
    
    static let shared = DefaultsManager()
    
    let defaults = UserDefaults.standard
    
    func saveUid(uid: String) {
        defaults.set(uid, forKey: "uid")
    }
    
    func fetchUID() -> String? {
        let user = defaults.object(forKey: "uid") as? String
        return user
    }
    
}
