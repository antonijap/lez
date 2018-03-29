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
    case relationship, friendship, sex
}

enum Diet: String {
    case vegan
    case vegetarian
    case omnivore
    case other
}

struct MatchingPreferences {
    var ageRange: (Int, Int)
    var location: String
    var lookingFor: [LookingFor]
}

struct Details {
    var about: String
    var dealBreakers: String
    var diet: Diet
}

struct Images {
    var imageURLs: [String]
}

class User {
    var id: Int
    var name: String
    var email: String
    var age: Int
    var location: String
    var isOnboarded = false
    var isPremium = false
    var isBanned = false
    var isHidden = false
    var matchingPreferences: MatchingPreferences
    var details: Details
    var images: Images?
    
    init(id: Int, name: String, email: String, age: Int, location: String, matchingPreferences: MatchingPreferences, details: Details, images: Images) {
        self.id = id
        self.name = name
        self.email = email
        self.age = age
        self.location = location
        self.matchingPreferences = matchingPreferences
        self.details = details
        self.images = images
    }
}
