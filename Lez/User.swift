//
//  User.swift
//  Lez
//
//  Created by Antonija Pek on 24/02/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Foundation

struct MatchingPreferences {
    var preferedAge: (Int, Int)?
}

class User {
    var id: Int
    var name: String?
    var email: String?
    var age: Int?
    var location: String?
    var isOnboarded = false
    var isPremium = false
    var matchingPreferences: MatchingPreferences?
    
    init(id: Int, name: String, email: String, age: Int, location: String, isOnboarded: Bool, isPremium: Bool, matchingPreferences: MatchingPreferences) {
        self.id = id
        self.name = name
        self.email = email
        self.age = age
        self.location = location
        self.isOnboarded = isOnboarded
        self.isPremium = isPremium
        self.matchingPreferences = matchingPreferences
    }
}
