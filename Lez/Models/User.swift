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

enum Diet: String, Encodable {
    case vegan = "Vegan"
    case vegetarian = "Vegetarian"
    case omnivore = "Omnivore"
    case other = "Other"
}

class User: Encodable, Hashable {
    var hashValue: Int { get { return uid.hashValue } }
    var uid: String
    var name: String
    var email: String
    var age: Int
    var location: Location
    var isOnboarded: Bool
    var isPremium: Bool
    var isBanned: Bool
    var isHidden: Bool
    var preferences: Preferences
    var details: Details
    var images: [String]?
    var likes: [String]?
    var dislikes: [String]?
    var blockedUsers: [String]?
    var chats: [String]?
    
    // Initial user cration, no images, flags are false
    convenience init(uid: String, name: String, email: String, age: Int, location: Location, preferences: Preferences, details: Details) {
        self.init(uid: uid, name: name, email: email, age: age, location: location, preferences: preferences, details: details, images: nil, isOnboarded: false, isPremium: false, isBanned: false, isHidden: false, likes: [], dislikes: [], blockedUsers: [], chats: [])
        self.uid = uid
        self.name = name
        self.email = email
        self.age = age
        self.location = location
        self.preferences = preferences
        self.details = details
    }
    
    // With everything
    init(uid: String, name: String, email: String, age: Int, location: Location, preferences: Preferences, details: Details, images: [String]?, isOnboarded: Bool, isPremium: Bool, isBanned: Bool, isHidden: Bool, likes: [String], dislikes: [String], blockedUsers: [String], chats: [String]) {
        self.uid = uid
        self.name = name
        self.email = email
        self.age = age
        self.location = location
        self.preferences = preferences
        self.details = details
        self.images = images
        self.isOnboarded = isOnboarded
        self.isPremium = isPremium
        self.isBanned = isBanned
        self.isHidden = isHidden
        self.likes = likes
        self.dislikes = dislikes
        self.blockedUsers = blockedUsers
        self.chats = chats
    }
    
    static func ==(left:User, right:User) -> Bool {
        return left.uid == right.uid
    }
}

struct Location: Encodable {
    var city: String
    var country: String
}

struct AgeRange: Encodable {
    var from: Int
    var to: Int
}

struct Preferences: Encodable {
    var ageRange: AgeRange
    var lookingFor: [String]
}

struct Details: Encodable {
    var about: String
    var dealBreakers: String
    var diet: Diet
}
