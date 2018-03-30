//
//  User.swift
//  Lez
//
//  Created by Antonija Pek on 24/02/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Foundation
import UIKit

enum LookingFor: String, Codable {
    case relationship = "Relationship", friendship = "Friendship", sex = "Sex"
}

enum Diet: String, Codable {
    case vegan = "Vegan"
    case vegetarian = "Vegetarian"
    case omnivore = "Omnivore"
    case other = "Other"
}

class User: Codable {
    var id: Int
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
    var images: Images?
    
    init(id: Int, name: String, email: String, age: Int, location: Location, preferences: Preferences, details: Details) {
        self.id = id
        self.name = name
        self.email = email
        self.age = age
        self.location = location
        self.preferences = preferences
        self.details = details
    }
}

struct Location: Codable {
    var city: String
    var country: String
}

struct AgeRange: Codable {
    var from: Int
    var to: Int
}

struct Preferences: Codable {
    var ageRange: AgeRange
    var lookingFor: [LookingFor]
}

struct Details: Codable {
    var about: String
    var dealBreakers: String
    var diet: Diet
}

struct Images: Codable {
    var imageURLs: [String]
}
