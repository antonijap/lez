//
//  FirestoreManager.swift
//  Lez
//
//  Created by Antonija on 01/04/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Foundation
import Firebase
import Promises

final class FirestoreManager {
    
    private init() { }
    
    let db = Firestore.firestore()
    static let shared = FirestoreManager()
    
    func addUser(uid: String, data: [String: Any]) -> Promise<Bool> {
        return Promise { fulfill, reject in
            self.db.collection("users").document(uid).setData(data) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                    reject(err)
                } else {
                    print("Document successfully updated")
                    fulfill(true)
                }
            }
        }
    }

    func fetchPotentialMatches() {
        
    }
    
    func fetchCurrentUser(uid: String) -> Promise<User> {
        return Promise { fulfill, reject in
            let docRef = self.db.collection("users").document(uid)
            docRef.getDocument { (document, error) in
                if let document = document {
                    if let user = self.parseFirebaseUser(document: document) {
                         fulfill(user)
                    }
                } else {
                    print("Document does not exist")
                    reject(error!)
                }
            }
        }
    }
    
    func updateImages(uid: String, urls: [String]) -> Promise<Bool>  {
        return Promise { fulfill, reject in
            let updateImagesRef = self.db.collection("users").document(uid)
            updateImagesRef.updateData([
                "images": urls
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                    reject(err)
                } else {
                    print("Document successfully updated")
                    fulfill(true)
                }
            }
        }
    }
    
    func parseFirebaseUser(document: DocumentSnapshot) -> User? {
        guard let data = document.data() else { return nil }
        guard let uid = data["uid"] as? String else {
            print("Problem with parsing uid.")
            return nil
        }
        guard let name = data["name"] as? String else {
            print("Problem with parsing name.")
            return nil
        }
        guard let email = data["email"] as? String else {
            print("Problem with parsing email.")
            return nil
        }
        guard let age = data["age"] as? Int else {
            print("Problem with parsing age.")
            return nil
        }
        guard let locationDict = data["location"] as? [String: String] else {
            print("Problem with parsing locationDict.")
            return nil
        }
        guard let city = locationDict["city"] else {
            print("Problem with parsing city.")
            return nil
        }
        guard let country = locationDict["country"] else {
            print("Problem with parsing country.")
            return nil
        }
        guard let isOnboarded = data["isOnboarded"] as? Bool else {
            print("Problem with parsing isOnboarded.")
            return nil
        }
        guard let isPremium = data["isPremium"] as? Bool else {
            print("Problem with parsing isPremium.")
            return nil
        }
        guard let isBanned = data["isBanned"] as? Bool else {
            print("Problem with parsing isBanned.")
            return nil
        }
        guard let isHidden = data["isHidden"] as? Bool else {
            print("Problem with parsing isHidden.")
            return nil
        }
        guard let preferencesDict = data["preferences"] as? [String: Any] else {
            print("Problem with parsing preferences.")
            return nil
        }
        guard let ageRangeDict = preferencesDict["ageRange"] as? [String: Int] else {
            print("Problem with parsing ageRangeDict.")
            return nil
        }
        guard let from = ageRangeDict["from"] else {
            print("Problem with parsing from.")
            return nil
        }
        guard let to = ageRangeDict["to"] else {
            print("Problem with parsing ageRange.")
            return nil
        }
        guard let lookingFor = preferencesDict["lookingFor"] as? [String] else {
            print("Problem with parsing lookingFor.")
            return nil
        }
        guard let detailsDict = data["details"] as? [String: String] else {
            print("Problem with parsing details")
            return nil
        }
        guard let about = detailsDict["about"] else {
            print("Problem with parsing about.")
            return nil
        }
        guard let dealBreakers = detailsDict["dealbreakers"] else {
            print("Problem with parsing dealbreakers.")
            return nil
        }
        guard let diet = detailsDict["diet"] else {
            print("Problem with parsing diet.")
            return nil
        }
        guard let images = data["images"] as? [String] else {
            print("Problem with parsing images.")
            return nil
        }
        
        let newLocation = Location(city: city, country: country)
        let newPreferences = Preferences(ageRange: AgeRange(from: from, to: to), lookingFor: lookingFor)
        let newDetails = Details(about: about, dealBreakers: dealBreakers, diet: Diet(rawValue: diet)!)
        let newUser = User(uid: uid, name: name, email: email, age: age, location: newLocation, preferences: newPreferences, details: newDetails, images: images, isOnboarded: isOnboarded, isPremium: isPremium, isBanned: isBanned, isHidden: isHidden)
        return newUser
    }
}
