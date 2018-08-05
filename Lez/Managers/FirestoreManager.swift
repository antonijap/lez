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
//
//    private init() {
//        let settings = db.settings
//        settings.areTimestampsInSnapshotsEnabled = true
//        db.settings = settings
//    }

    func addReport(data: [String: Any]) -> Promise<Bool> {
        return Promise { fulfill, reject in
            self.db.collection("reports").addDocument(data: data) { error in
                guard error == nil else { print("Error creating report: \(error.debugDescription)"); reject(error!); return }
                print("Reported!")
                fulfill(true)
            }
        }
    }

    func addUser(uid: String, data: [String: Any]) -> Promise<Bool> {
        return Promise { fulfill, reject in
            self.db.collection("users").document(uid).setData(data) { error in
                guard error == nil else { print("Error updating document: \(error.debugDescription)"); reject(error!); return }
                print("Document successfully updated")
                fulfill(true)
            }
        }
    }

    func fetchPotentialMatches(for user: User) -> Promise<[User]> {
        return Promise { fulfill, reject in
            print("Mark: \(Date().toString(dateFormat: "hh:mm:ss"))")
            let from = user.preferences.ageRange.from
            let to = user.preferences.ageRange.to
//            let suitableAges = Set(from...to)
            let group = DispatchGroup()
            var allUsers: Set<User> = []

            let potentialMatchesRef: Query!
            print(user.uid)
            if DefaultsManager.shared.fetchToggleAllLesbians() {
                print("Toggle all lesbians is TRUE.")
                potentialMatchesRef = self.db.collection("users")
                    .whereField("isBanned", isEqualTo: false)
                    .whereField("isHidden", isEqualTo: false)
                    .whereField("age", isGreaterThanOrEqualTo: from)
                    .whereField("age", isLessThanOrEqualTo: to)
            } else if DefaultsManager.shared.PreferedLocationExists() { // Use preferred location
                print("Prefered location: \(DefaultsManager.shared.fetchPreferedLocation())")
                potentialMatchesRef = self.db.collection("users")
                    .whereField("isBanned", isEqualTo: false)
                    .whereField("isHidden", isEqualTo: false)
                    .whereField("age", isGreaterThanOrEqualTo: from)
                    .whereField("age", isLessThanOrEqualTo: to)
            } else { // Use default location
                print("No prefered location.")
                potentialMatchesRef = self.db.collection("users")
                    .whereField("isBanned", isEqualTo: false)
                    .whereField("isHidden", isEqualTo: false)
                    .whereField("location.city", isEqualTo: user.location.city)
                    .whereField("age", isGreaterThanOrEqualTo: from)
                    .whereField("age", isLessThanOrEqualTo: to)
            }

            potentialMatchesRef.getDocuments { querySnapshot, error in
                guard let currentUser = Auth.auth().currentUser else { return }
                guard error == nil else { print("Error getting documents: \(error.debugDescription)"); return }
                guard let snapshot = querySnapshot else { print("Error with snapshot"); return }

                print("Mark final document \(snapshot.documents)")

                for document in snapshot.documents {
                    group.enter()
                    FirestoreManager.shared.parseFirebaseUser(document: document).then({ user in
                        allUsers.update(with: user!)
                        group.leave()
                    })
                }
  
                group.notify(queue: .main) {
                    let blockedUsers: [String] = user.blockedUsers ?? [] // Consider making user.blockedUsers not nullable
                    let filteredUsers = allUsers.filter{ $0.uid != currentUser.uid } // Remove yourself
                                                .filter{ !blockedUsers.contains($0.uid) } // Remove blocked users
//                                                .filter{ suitableAges.contains($0.age) } // Remove users outside suitable ages
//                                                .filter{ $0.preferences.lookingFor.contains(where: user.preferences.lookingFor.contains) }
                    if DefaultsManager.shared.fetchToggleAllLesbians() {
                        fulfill(Array(filteredUsers))
                    } else if DefaultsManager.shared.PreferedLocationExists() {
                        let locationFilteredUsers =
                            filteredUsers.filter{ $0.location.country.contains(DefaultsManager.shared.fetchPreferedLocation()) ||
                                                  $0.location.city.contains(DefaultsManager.shared.fetchPreferedLocation()) }
                        fulfill(Array(locationFilteredUsers))
                    } else {
                        fulfill(Array(filteredUsers))
                    }
                }
            }
        }
    }

    func fetchUser(uid: String) -> Promise<User> {
        return Promise { fulfill, reject in
            let docRef = self.db.collection("users").document(uid)
            docRef.getDocument { document, error in
                guard let document = document else { print("Document does not exist"); reject(error!); return }
                self.parseFirebaseUser(document: document).then({ user in if let user = user { fulfill(user) } })
            }
        }
    }

    func checkIfUserExists(uid: String) -> Promise<Bool> {
        return Promise { fulfill, reject in
            print(uid)
            let docRef = self.db.collection("users").document(uid)
            docRef.getDocument { document, error in
                guard let document = document else { print("Document does not exist"); fulfill(false); return }
                guard document.data() != nil else { fulfill(false); return }
                guard error == nil else { reject(error!); return }
                fulfill(true)
            }
        }
    }

    func updateUser(uid: String, data: [String: Any]) -> Promise<Bool> {
        return Promise { fulfill, reject in
            let docRef = self.db.collection("users").document(uid)
            docRef.updateData(data) { error in
                guard error == nil else { print("Error updating document: \(error.debugDescription)"); reject(error!); return }
                print("Document successfully updated")
                fulfill(true)
            }
        }
    }
    
    func updateImages(uid: String, urls: [String]) -> Promise<Bool>  {
        return Promise { fulfill, reject in
            let updateImagesRef = self.db.collection("users").document(uid)
            updateImagesRef.updateData(["images": urls]) { error in
                guard error == nil else { print("Error updating document: \(error.debugDescription)"); reject(error!); return }
                print("Document successfully updated")
                fulfill(true)
            }
        }
    }
    
    func parseFirebaseUser(document: DocumentSnapshot) -> Promise<User?> {
        return Promise { fulfill, reject in
            guard let data = document.data() else { print("Problem with data"); return }
            guard let uid = data["uid"] as? String else { print("Problem with parsing uid."); return }
            guard let name = data["name"] as? String else { print("Problem with parsing name."); return }
            guard let email = data["email"] as? String else { print("Problem with parsing email."); return }
            guard let age = data["age"] as? Int else { print("Problem with parsing age."); return }
            guard let locationDict = data["location"] as? [String: String] else {
                print("Problem with parsing locationDict."); return
            }
            guard let city = locationDict["city"] else { print("Problem with parsing city."); return }
            guard let country = locationDict["country"] else { print("Problem with parsing country."); return }
            guard let isOnboarded = data["isOnboarded"] as? Bool else { print("Problem with parsing isOnboarded."); return }
            guard let isPremium = data["isPremium"] as? Bool else { print("Problem with parsing isPremium."); return }
            guard let isBanned = data["isBanned"] as? Bool else { print("Problem with parsing isBanned."); return }
            guard let isHidden = data["isHidden"] as? Bool else { print("Problem with parsing isHidden."); return }
            guard let preferencesDict = data["preferences"] as? [String: Any] else {
                print("Problem with parsing preferences."); return
            }
            guard let ageRangeDict = preferencesDict["ageRange"] as? [String: Int] else {
                print("Problem with parsing ageRangeDict."); return
            }
            guard let from = ageRangeDict["from"] else { print("Problem with parsing from."); return }
            guard let to = ageRangeDict["to"] else { print("Problem with parsing to."); return }
            guard let lookingFor = preferencesDict["lookingFor"] as? [String] else {
                print("Problem with parsing lookingFor."); return
            }
            guard let detailsDict = data["details"] as? [String: String] else { print("Problem with parsing details"); return }
            guard let about = detailsDict["about"] else { print("Problem with parsing about."); return }
            guard let dealBreakers = detailsDict["dealbreakers"] else { print("Problem with parsing dealbreakers."); return }
            guard let diet = detailsDict["diet"] else { print("Problem with parsing diet."); return }
            guard let images = data["images"] as? [String] else { print("Problem with parsing images."); return }
            guard let likes = data["likes"] as? [String] else { print("Problem with parsing likes."); return }
            guard let blockedUsers = data["blockedUsers"] as? [String] else {
                print("Problem with parsing blocked users."); return
            }
            guard let chats = data["chats"] as? [String] else { print("Problem with parsing chats."); return }

            guard let likesLeft = data["likesLeft"] as? Int else { print("Problem with parsing likesLeft."); return }
            guard let cooldownTime = data["cooldownTime"] as? String else { print("Problem with parsing cooldownTime."); return }
            guard let isManuallyPromoted = data["isManuallyPromoted"] as? Bool else {
                print("Problem with parsing isManuallyPromoted."); return
            }

            let group = DispatchGroup()

            // Create URL
            var newLezImage: LezImage!
            var newLezImages: [LezImage] = []

            for name in images {
                group.enter()
                self.generateURL(uid: uid, name: name).then { (url) in
                    newLezImage = LezImage(name: name, url: url)
                    newLezImages.append(newLezImage)
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                let newLocation = Location(city: city, country: country)
                let newPreferences = Preferences(ageRange: AgeRange(from: from, to: to), lookingFor: lookingFor)
                let newDetails = Details(about: about, dealBreakers: dealBreakers, diet: Diet(rawValue: diet)!)
                let newUser = User(uid: uid, name: name, email: email, age: age, location: newLocation, preferences: newPreferences, details: newDetails, images: newLezImages, isOnboarded: isOnboarded, isPremium: isPremium, isBanned: isBanned, isHidden: isHidden, likes: likes, blockedUsers: blockedUsers, chats: chats, likesLeft: likesLeft, cooldownTime: cooldownTime.date(format: .custom("yyyy-MM-dd HH:mm:ss"))?.absoluteDate, isManuallyPromoted: isManuallyPromoted)
                fulfill(newUser)
            }
        }
    }

    func fetchMessages(uid: String) -> Promise<[Message]?> {
        return Promise { fulfill, _ in
            var messages: [Message] = []
            let docRef = self.db.collection("chats").document(uid).collection("messages")
            docRef.getDocuments { (document, error) in
                guard let document = document else { print("Document does not exist"); fulfill(nil); return  }
                for item in document.documents {
                    guard let from = item["from"] as? String else { print("Problem with parsing from."); return }
                    guard let created = item["created"] as? String else { print("Problem with parsing created."); return }
                    guard let message = item["message"] as? String else { print("Problem with parsing message."); return }

                    let newMessage = Message(created: created, from: from, message: message)
                    messages.append(newMessage)
                }
                fulfill(messages)
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
                    guard let document = document else { print("Document does not exist"); return }
                    self.parseFirebaseChat(document: document).then({ chat in
                        fetchedChats.append(chat)
                        group.leave()
                    })
                }
            }
            group.notify(queue: .main, execute: { fulfill(fetchedChats) })
        }
    }

    func parseFirebaseChat(document: DocumentSnapshot) -> Promise<Chat> {
        return Promise { fulfill, reject in
            guard let data = document.data() else { return }
            let group = DispatchGroup()
            var participants: [User] = []

            guard let uid = data["uid"] as? String else { print("Problem with parsing uid."); return }
            guard let created = data["created"] as? String else { print("Problem with parsing created."); return }
            guard let lastUpdated = data["lastUpdated"] as? String else { print("Problem with parsing lastUpdated."); return }
            guard let participantsObject = data["participants"] as? NSObject else { print("Problem with parsing participants."); return }
            guard let participantsDictionary = participantsObject as? Dictionary<String, Bool> else {
                print("Problem with parsing participantsDictionary."); return
            }
            guard let isDisabled = data["isDisabled"] as? Bool else { print("Problem with parsing isDisabled."); return }

            for item in participantsDictionary {
                group.enter()
                FirestoreManager.shared.fetchUser(uid: item.key).then { user in
                    participants.append(user)
                    group.leave()
                }
            }
            group.notify(queue: .main, execute: {
                self.fetchMessages(uid: uid).then({ messages in
                    if let messages = messages {
                        if messages.count > 0 {
                            fulfill(Chat(uid: uid, created: created, lastUpdated: lastUpdated, participants: participants, messages: messages, isDisabled: isDisabled))
                        } else {
                            fulfill(Chat(uid: uid, created: created, lastUpdated: lastUpdated, participants: participants, messages: nil, isDisabled: isDisabled))
                        }
                    }
                })
            })
        }
    }

    func parseMessage(document: DocumentSnapshot) -> Promise<Message> {
        return Promise { fulfill, reject in
            guard let data = document.data() else { return }
            guard let message = data["message"] as? String else { print("Problem with parsing messaage."); return }
            guard let from = data["from"] as? String else { print("Problem with parsing from."); return }
            guard let created = data["created"] as? String else { print("Problem with parsing message created."); return }
            let newMessage = Message(created: created, from: from, message: message)
            fulfill(newMessage)
        }
    }

    func addEmptyChat(data: [String: Any], for uid: String, herUid: String) -> Promise<String> {
        return Promise { fulfill, reject in
            let group = DispatchGroup()
            let newChatRef = self.db.collection("chats").addDocument(data: data) { error in
                group.enter()
                if let error = error {
                    print("Error creating report: \(error)")
                    reject(error); return
                }
                group.leave()
            }

            group.notify(queue: .main, execute: {
                self.fetchUser(uid: uid).then({ user in
                    var chats: [String] = []
                    for chat in user.chats! { chats.append(chat) }
                    chats.append(newChatRef.documentID)
                    let data: [String: Any] = ["chats": chats]
                    self.updateUser(uid: uid, data: data).then({ (success) in
                        if success {
                            let data: [String: Any] = ["uid": newChatRef.documentID] // Add UID to chat
                            let docRef = self.db.collection("chats").document(newChatRef.documentID)
                            docRef.updateData(data) { error in
                                if let error = error {
                                    print("Error updating document: \(error)")
                                    reject(error); return
                                }
                                self.fetchUser(uid: herUid).then({ (her) in
                                    var chats: [String] = []
                                    for chat in her.chats! { chats.append(chat) }
                                    chats.append(newChatRef.documentID)
                                    let data: [String: Any] = ["chats": chats]
                                    self.updateUser(uid: herUid, data: data).then({ success in
                                        if success { fulfill(newChatRef.documentID) }
                                    })
                                })
                            }
                        }
                    })
                })
            })
        }
    }

    func addNewMessage(to chat: String, data: [String: Any]) -> Promise<Bool> {
        return Promise { fulfill, reject in
            self.db.collection("chats").document(chat).collection("messages").addDocument(data: data) { error in
                if let error = error {
                    print("Error writing document: \(error)")
                    reject(error); return
                }
                let d: [String: Any] = ["lastUpdated": Date().toString(dateFormat: "yyyy-MM-dd HH:mm:ss")]
                self.db.collection("chats").document(chat).updateData(d) { error in
                    if let error = error {
                        print("Error writing document: \(error)")
                        reject(error); return
                    }
                    fulfill(true)
                }
            }
            
        }
    }

    func generateURL(uid: String, name: String) -> Promise<String> {
        return Promise { fufill, reject in
            // Create a reference to the file you want to download
            let ref = Storage.storage().reference().child("images/\(uid)/\(name)")
            // Fetch the download URL
            ref.downloadURL { url, error in
                if let error = error {
                    print(error.localizedDescription)
                    reject(error); return
                }
                fufill(url!.absoluteString)
            }
        }
    }
    
    func deleteUser(uid: String) -> Promise<Bool> {
        return Promise { fulfill, reject in
            self.db.collection("users").document(uid).delete() { error in
                if let error = error { reject(error); return }
                fulfill(true)
            }
        }
    }
}
