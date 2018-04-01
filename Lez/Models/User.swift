//
//  User.swift
//  Lez
//
//  Created by Antonija Pek on 24/02/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Foundation
import UIKit

enum LookingFor: String {
    case relationship = "Relationship", friendship = "Friendship", sex = "Sex"
}

enum Diet: String {
    case vegan = "Vegan"
    case vegetarian = "Vegetarian"
    case omnivore = "Omnivore"
    case other = "Other"
}

class User {
    var uid: String
    var name: String
    var email: String
    var age: Int
    var location: Location
    var isOnboarded = false
    var isPremium = false
    var isBanned = false
    var isHidden = false
    var preferences: Preferences
    var details: Details
    var images: [String]?
    
    init(uid: String, name: String, email: String, age: Int, location: Location, preferences: Preferences, details: Details) {
        self.uid = uid
        self.name = name
        self.email = email
        self.age = age
        self.location = location
        self.preferences = preferences
        self.details = details
    }
}

struct Location {
    var city: String
    var country: String
}

struct AgeRange {
    var from: Int
    var to: Int
}

struct Preferences {
    var ageRange: AgeRange
    var lookingFor: [String]
}

struct Details {
    var about: String
    var dealBreakers: String
    var diet: Diet
}
