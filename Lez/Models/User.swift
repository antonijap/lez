//
//  User.swift
//  Lez
//
//  Created by Antonija Pek on 24/02/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Foundation
import UIKit
import Firebase

enum LookingFor: String {
    case relationship = "Relationship", friendship = "Friendship", sex = "Sex"
}

enum Diet: String, Encodable {
    case vegan = "Vegan"
    case vegetarian = "Vegetarian"
    case omnivore = "Omnivore"
    case other = "Other"
}

struct Location: Encodable {
    var city: String
    var country: String
}

struct AgeRange: Encodable, Equatable {
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

struct LezImage: Encodable {
    var name: String
    var url: String
}

class User: Hashable {
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
    var images: [LezImage]
    var likes: [String]?
    var blockedUsers: [String]?
    var chats: [String]?
    var likesLeft: Int
    var cooldownTime: Date?
    var isManuallyPromoted: Bool

    init(uid: String, name: String, email: String, age: Int, location: Location, preferences: Preferences, details: Details, images: [LezImage], isOnboarded: Bool, isPremium: Bool, isBanned: Bool, isHidden: Bool, likes: [String], blockedUsers: [String], chats: [String], likesLeft: Int, cooldownTime: Date?, isManuallyPromoted: Bool) {
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
        self.blockedUsers = blockedUsers
        self.chats = chats
        self.likesLeft = likesLeft
        self.cooldownTime = cooldownTime
        self.isManuallyPromoted = isManuallyPromoted
    }
    
    static func ==(left:User, right:User) -> Bool {
        return left.uid == right.uid
    }
}
