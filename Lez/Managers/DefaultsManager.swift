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
    private let defaults = UserDefaults.standard
    
    func save(number: Int) {
        defaults.set(number, forKey: "number")
    }
    
    func fetchNumber() -> Int {
        let number = defaults.object(forKey: "number") as! Int
        return number
    }
    
    func saveToggleAllLesbians(value: Bool) {
        defaults.set(value, forKey: "toggleAll")
    }
    
    func fetchToggleAllLesbians() -> Bool {
        let toggle = defaults.object(forKey: "toggleAll") as! Bool
        return toggle
    }
    
    func ifToggleAllLesbiansExists() -> Bool {
        return defaults.object(forKey: "toggleAll") != nil
    }
    
}
