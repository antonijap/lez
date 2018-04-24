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
    
    let db = Firestore.firestore()
    static let shared = FirestoreManager()
    
    private init() {
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
    }
    
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

    func fetchPotentialMatches(for user: User) -> Promise<[User]> {
        return Promise { fulfill, reject in
            let from = user.preferences.ageRange.from
            let to = user.preferences.ageRange.to
            let suitableAges = Array(from...to)
            
            var allUsers: [User] = []
            
            let potentialMatchesRef = self.db.collection("users")
                .whereField("isBanned", isEqualTo: false)
                .whereField("isHidden", isEqualTo: false)
                .whereField("location.country", isEqualTo: user.location.country)
            
            potentialMatchesRef.getDocuments { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        //                    print("\(document.documentID) => \(document.data())")
                        let user = FirestoreManager.shared.parseFirebaseUser(document: document)
                        allUsers.append(user!)
                    }
                }
                
                // Get rid of all users outside suitable ages
                var filteredAge: [User] = []
                for match in allUsers {
                    if suitableAges.contains(match.age) {
                        filteredAge.append(match)
                    }
                }
                
                // Get the ones with the same preferences.lookingFor
                var filteredLookingFor: [User] = []
                for match in filteredAge {
                    for lookingFor in user.preferences.lookingFor {
                        if match.preferences.lookingFor.contains(lookingFor) {
                            filteredLookingFor.append(match)
                        }
                    }
                }
                
                // Remove yourself
                var filteredMe: [User] = []
                guard let currentUser = Auth.auth().currentUser else { return }
                for match in filteredLookingFor {
                    if match.uid != currentUser.uid {
                        filteredMe.append(match)
                    }
                }
                
                var finalArray: [User] = filteredMe
                
                // Remove all liked users
                for match in filteredMe {
                    for like in user.likes! {
                        if let index = finalArray.index(where: { _ in like == match.uid }) {
                            finalArray.remove(at: index)
                            print("User liked, removing...")
                        }
                    }
                }

                
                // Remove all disliked users
                for match in filteredMe {
                    for dislike in user.dislikes! {
                        if let index = finalArray.index(where: { _ in dislike == match.uid }) {
                            finalArray.remove(at: index)
                            print("User disliked, removing...")
                        }
                    }
                }
                fulfill(Array(Set(finalArray)))
            }
        }
    }
    
    func fetchUser(uid: String) -> Promise<User> {
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
    
    func updateCurrentUser(uid: String, data: [String: Any]) -> Promise<Bool> {
        return Promise { fulfill, reject in
            let docRef = self.db.collection("users").document(uid)
            docRef.updateData(data) { err in
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
    
    func checkIfLikedUserIsMatch(currentUserUid: String, likedUserUid: String) -> Promise<Bool> {
        return Promise { fulfill, reject in
            self.fetchUser(uid: likedUserUid).then({ (user) in
                guard let likes = user.likes else { return }
                if likes.contains(currentUserUid) {
                    print("It's a MATCH!")
                    fulfill(true)
                }
            })
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
            print("Problem with parsing to.")
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
        
        guard let likes = data["likes"] as? [String] else {
            print("Problem with parsing likes.")
            return nil
        }
        
        guard let dislikes = data["dislikes"] as? [String] else {
            print("Problem with parsing dislikes.")
            return nil
        }
        
        let newLocation = Location(city: city, country: country)
        let newPreferences = Preferences(ageRange: AgeRange(from: from, to: to), lookingFor: lookingFor)
        let newDetails = Details(about: about, dealBreakers: dealBreakers, diet: Diet(rawValue: diet)!)
        let newUser = User(uid: uid, name: name, email: email, age: age, location: newLocation, preferences: newPreferences, details: newDetails, images: images, isOnboarded: isOnboarded, isPremium: isPremium, isBanned: isBanned, isHidden: isHidden, likes: likes, dislikes: dislikes)
        return newUser
    }
}
