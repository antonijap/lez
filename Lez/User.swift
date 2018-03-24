//
//  User.swift
//  Lez
//
//  Created by Antonija Pek on 24/02/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Foundation
import UIKit

struct MatchingPreferences {
    var preferedAge: (Int, Int)?
}

struct UserData {
    var about: String?
    var dealBreakers: String?
}

struct UserImages {
    var imageURLs: [String]?
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
    var userData: UserData?
    var userImages: UserImages?
    
    init(id: Int, name: String, email: String, age: Int, location: String, isOnboarded: Bool, isPremium: Bool, matchingPreferences: MatchingPreferences, userData: UserData, userImages: UserImages) {
        self.id = id
        self.name = name
        self.email = email
        self.age = age
        self.location = location
        self.isOnboarded = isOnboarded
        self.isPremium = isPremium
        self.matchingPreferences = matchingPreferences
        self.userData = userData
        self.userImages = userImages
    }
}
