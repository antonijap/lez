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
    
    func addReport(data: [String: Any]) -> Promise<Bool> {
        return Promise { fulfill, reject in
            self.db.collection("reports").addDocument(data: data, completion: { (err) in
                if let err = err {
                    print("Error creating report: \(err)")
                    reject(err)
                } else {
                    print("Reported!")
                    fulfill(true)
                }
            })
        }
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
    
    func fetchMatchedUsers() -> Promise<[User]> {
        return Promise { fulfill, reject in
            var matchedUsers: [String] = []
            var users: [User] = []
            let group = DispatchGroup()
            
            if let currentUser = Auth.auth().currentUser {
                self.fetchUser(uid: currentUser.uid).then({ (user) in
                    for like in user.likes! {
                        group.enter()
                        self.checkIfLikedUserIsMatch(currentUserUid: currentUser.uid, likedUserUid: like).then({ (success) in
                            if success {
                                matchedUsers.append(like)
                                group.leave()
                            }
                        })
                    }
                    group.notify(queue: .main, execute: {
                        for uid in matchedUsers {
                            group.enter()
                            self.fetchUser(uid: uid).then({ (user) in
                                users.append(user)
                                group.leave()
                            })
                        }
                        group.notify(queue: .main, execute: {
                            fulfill(users)
                        })
                    })
                })
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
                guard let currentUser = Auth.auth().currentUser else { return }

                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
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
                for match in Array(Set(filteredLookingFor)) {
                    if match.uid != currentUser.uid {
                        filteredMe.append(match)
                    }
                }
                
                var finalArray: [User] = Array(Set(filteredMe))
                
                // Remove all liked users
//                for matchedUser in finalArray {
//                    for like in user.likes! {
//                        if let index = finalArray.index(where: { _ in like == matchedUser.uid }) {
//                            finalArray.remove(at: index)
//                            print("User liked, removing... \(matchedUser.name)")
//                        }
//                    }
//                }
                
                for _ in finalArray {
                    if let i = finalArray.index(where: { user.likes!.contains($0.uid) }) {
                        finalArray.remove(at: i)
                    }
                }
                
                // Remove all disliked users
//                for match in finalArray {
//                    for dislike in user.dislikes! {
//                        if let index = finalArray.index(where: { _ in dislike == match.uid }) {
//                            finalArray.remove(at: index)
//                            print("User disliked, removing...")
//                        }
//                    }
//                }
                
                for _ in finalArray {
                    if let i = finalArray.index(where: { user.dislikes!.contains($0.uid) }) {
                        finalArray.remove(at: i)
                    }
                }
                
                // Remove blocked users
//                for match in finalArray {
//                    for blocked in user.blockedUsers! {
//                        if let index = finalArray.index(where: { _ in blocked == match.uid }) {
//                            finalArray.remove(at: index)
//                            print("User blocked, removing...")
//                        }
//                    }
//                }
                
                if let i = finalArray.index(where: { user.blockedUsers!.contains($0.uid) }) {
                    print(i)
                    print("User blocked, removing...")
                    finalArray.remove(at: i)
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
    
    func checkIfUserExists(uid: String) -> Promise<Bool> {
        return Promise { fulfill, reject in
            let docRef = self.db.collection("users").document(uid)
            docRef.getDocument { (document, error) in
                if let document = document {
                    if document.data() == nil {
                       fulfill(false)
                    } else {
                        reject(error!)
                    }
                } else {
                    print("Document does not exist")
                    fulfill(false)
                }
            }
        }
    }
    
    func updateUser(uid: String, data: [String: Any]) -> Promise<Bool> {
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
        
        guard let blockedUsers = data["blockedUsers"] as? [String] else {
            print("Problem with parsing blocked users.")
            return nil
        }
        
        guard let chats = data["chats"] as? [String] else {
            print("Problem with parsing chats.")
            return nil
        }
        
        let newLocation = Location(city: city, country: country)
        let newPreferences = Preferences(ageRange: AgeRange(from: from, to: to), lookingFor: lookingFor)
        let newDetails = Details(about: about, dealBreakers: dealBreakers, diet: Diet(rawValue: diet)!)
        let newUser = User(uid: uid, name: name, email: email, age: age, location: newLocation, preferences: newPreferences, details: newDetails, images: images, isOnboarded: isOnboarded, isPremium: isPremium, isBanned: isBanned, isHidden: isHidden, likes: likes, dislikes: dislikes, blockedUsers: blockedUsers, chats: chats)
        return newUser
    }
    
    func fetchMessages(uid: String) -> Promise<[Message]?> {
        return Promise { fulfill, _ in
            var messages: [Message] = []
            let docRef = self.db.collection("chats").document(uid).collection("messages")
            docRef.getDocuments { (document, error) in
                if let document = document {
                    for item in document.documents {
                        guard let from = item["from"] as? String else {
                            print("Problem with parsing from.")
                            return
                        }
                        guard let created = item["created"] as? Timestamp else {
                            print("Problem with parsing created.")
                            return
                        }
                        guard let message = item["message"] as? String else {
                            print("Problem with parsing message.")
                            return
                        }
                        
                        let newMessage = Message(created: created, from: from, message: message)
                        messages.append(newMessage)
                    }
                    fulfill(messages)
                } else {
                    print("Document does not exist")
                    fulfill(nil)
                }
            }
        }
    }
    
    func fetchChats(chats: [String]) -> Promise<[Chat]> {
        return Promise { fulfill, reject in
            let group = DispatchGroup()
            var fetchedChats: [Chat] = []
            for chat in chats {
                group.enter()
                let docRef = self.db.collection("chats").document(chat)
                docRef.getDocument { (document, error) in
                    if let document = document {
                        self.parseFirebaseChat(document: document).then({ (chat) in
                            fetchedChats.append(chat)
                            group.leave()
                        })
                    } else {
                        print("Document does not exist")
                    }
                }
            }
            
            group.notify(queue: .main, execute: {
                fulfill(fetchedChats)
            })
        }
        
    }
    
    func parseFirebaseChat(document: DocumentSnapshot) -> Promise<Chat> {
        return Promise { fulfill, reject in
            guard let data = document.data() else { return }
            let group = DispatchGroup()
            var participants: [User] = []

            guard let uid = data["uid"] as? String else {
                print("Problem with parsing uid.")
                return
            }
            
            guard let created = data["created"] as? Timestamp else {
                print("Problem with parsing created.")
                return
            }
            
            guard let lastUpdated = data["lastUpdated"] as? Timestamp else {
                print("Problem with parsing lastUpdated.")
                return
            }
            
            guard let participantsArray = data["participants"] as? [String] else {
                print("Problem with parsing participants.")
                return
            }
            
            for p in participantsArray {
                group.enter()
                FirestoreManager.shared.fetchUser(uid: p).then { (user) in
                    participants.append(user)
                    group.leave()
                }
            }
            
            group.notify(queue: .main, execute: {
                self.fetchMessages(uid: uid).then({ (messages) in
                    if let messages = messages {
                        if messages.count > 0 {
                            fulfill(Chat(uid: uid, created: created, lastUpdated: lastUpdated, participants: participants, messages: messages))
                        } else {
                            fulfill(Chat(uid: uid, created: created, lastUpdated: lastUpdated, participants: participants, messages: nil))
                        }
                    }
                })
            })
        }
    }
    
    func parseMessage(document: DocumentSnapshot) -> Promise<Message> {
        return Promise { fulfill, reject in
            guard let data = document.data() else { return }
            
            guard let message = data["message"] as? String else {
                print("Problem with parsing messaage.")
                return
            }
            
            guard let from = data["from"] as? String else {
                print("Problem with parsing from.")
                return
            }
            
            guard let created = data["created"] as? Timestamp else {
                print("Problem with parsing message created.")
                return
            }
            
            let newMessage = Message(created: created, from: from, message: message)
            fulfill(newMessage)
        }
    }
    
    func liveFetchMessages(uid: String) -> Promise<[Message]> {
        return Promise { fulfill, _ in
            var messages = [Message]()
            let group = DispatchGroup()
            
            self.db.collection("chats").document(uid).collection("messages").addSnapshotListener { (snapshot, error) in
                guard let document = snapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
                for message in document.documents {
                    group.enter()
                    self.parseMessage(document: message).then({ (message) in
                        messages.append(message)
                        group.leave()
                    })
                }
                group.notify(queue: .main, execute: {
                    fulfill(messages)
                })
            }
        }
    }
    
    func addEmptyChat(data: [String: Any], for uid: String, herUid: String) -> Promise<Bool> {
        return Promise { fulfill, reject in
            let group = DispatchGroup()
            let newChatRef = self.db.collection("chats").addDocument(data: data, completion: { (err) in
                group.enter()
                if let err = err {
                    print("Error creating report: \(err)")
                    reject(err)
                } else {
                    print("Added")
                    group.leave()
                }
            })
            
            group.notify(queue: .main, execute: {
                self.fetchUser(uid: uid).then({ (user) in
                    var chats: [String] = []
                    for chat in user.chats! {
                        chats.append(chat)
                    }
                    chats.append(newChatRef.documentID)
                    let data: [String: Any] = [
                        "chats": chats
                    ]
                    self.updateUser(uid: uid, data: data).then({ (success) in
                        if success {
                            // Add UID to chat
                            let data: [String: Any] = [
                                "uid": newChatRef.documentID
                            ]
                            let docRef = self.db.collection("chats").document(newChatRef.documentID)
                            docRef.updateData(data) { err in
                                if let err = err {
                                    print("Error updating document: \(err)")
                                    reject(err)
                                } else {
                                    self.fetchUser(uid: herUid).then({ (her) in
                                        var chats: [String] = []
                                        for chat in her.chats! {
                                            chats.append(chat)
                                        }
                                        chats.append(newChatRef.documentID)
                                        let data: [String: Any] = [
                                            "chats": chats
                                        ]
                                        self.updateUser(uid: herUid, data: data).then({ (success) in
                                            if success {
                                                fulfill(true)
                                            }
                                        })
                                    })
                                }
                            }
                        }
                    })
                })
            })
        }
    }
    
    func addNewMessage(to chat: String, data: [String: Any]) -> Promise<Bool> {
        return Promise { fulfill, reject in
            self.db.collection("chats").document(chat).collection("messages").addDocument(data: data, completion: { (err) in
                if let err = err {
                    print("Error writing document: \(err)")
                    reject(err)
                } else {
                    let d: [String: Any] = [
                        "lastUpdated": FieldValue.serverTimestamp()
                    ]
                    self.db.collection("chats").document(chat).updateData(d, completion: { (error) in
                        if let err = err {
                            print("Error writing document: \(err)")
                            reject(err)
                        } else {
                            fulfill(true)
                        }
                    })
                }     
            })
            
        }
    }
}
