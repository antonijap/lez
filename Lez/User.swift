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

struct User {
    var name: String?
    var email: String?
    var age: Int?
    var location: String?
    var isOnboarded = false
    var isPremium = false
    var matchingPreferences: MatchingPreferences?
}
