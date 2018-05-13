//
//  SetupProfileViewController.swift
//  Lez
//
//  Created by Antonija Pek on 25/03/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import UIKit
import Eureka
import GooglePlacesRow
import GooglePlaces
import Alertift
import Firebase

class UserProfileFormViewController: FormViewController {
    
    var loc: Location?
    var name: String?
    var email: String?
    var uid: String?
    var user: User?
    var delegate: ProfileViewControllerDelegate?
    var handle: AuthStateDidChangeListenerHandle?
    var onboardingContinues = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupForm()
        setupNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        handle = Auth.auth().addStateDidChangeListener { auth, user in
            if let user = user {
                Firestore.firestore().collection("users").document(user.uid).getDocument { documentSnapshot, error in
                    guard let document = documentSnapshot else {
                        print("Error fetching document: \(error!)")
                        return
                    }
                    guard let data = document.data() else { return }
                    
                    guard let isOnboarded = data["isOnboarded"] as? Bool else {
                        print("Problem with parsing isOnboarded.")
                        return
                    }
                    
                    if isOnboarded {
                        FirestoreManager.shared.fetchUser(uid: user.uid).then { (user) in
                            self.user = user
                            self.loc = Location(city: user.location.city, country: user.location.country)
                            self.uid = user.uid
                        }
                    }
                    self.onboardingContinues = true
                }
            }
        }
        
    }
    
    func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(self.submit))
        if let _ = user {
           // There is user show back button
            navigationItem.title = "Your Profile"
        } else {
            navigationItem.title = "Edit Profile"
            navigationItem.setHidesBackButton(true, animated: true)
        }
    }
    
    func parseFormIntoData() -> [String: Any]? {
        guard let nameRow: NameRow = form.rowBy(tag: "name") else { return nil }
        guard let name = nameRow.value else { return nil }
        
        guard let emailRow: EmailRow = form.rowBy(tag: "email") else { return nil }
        guard let email = emailRow.value else { return nil }
        
        guard let ageRow: IntRow = form.rowBy(tag: "age") else { return nil }
        guard let age = ageRow.value else { return nil }
        
        guard let aboutRow: TextRow = form.rowBy(tag: "about") else { return nil }
        guard let about = aboutRow.value else { return nil }
        
        guard let dietRow: PushRow<String> = form.rowBy(tag: "diet") else { return nil }
        guard let diet = dietRow.value else { return nil }
        
        guard let lookingForRow: MultipleSelectorRow<String> = form.rowBy(tag: "lookingFor") else { return nil }
        guard let lookingFor = lookingForRow.value else { return nil }
        var lookingForArray: [String] = []
        for l in lookingFor {
            if l == LookingFor.friendship.rawValue {
                lookingForArray.append(LookingFor.friendship.rawValue)
            } else if l == LookingFor.relationship.rawValue {
                lookingForArray.append(LookingFor.relationship.rawValue)
            } else if l == LookingFor.sex.rawValue {
                lookingForArray.append(LookingFor.sex.rawValue)
            }
        }
        
        guard let dealbreakersRow: TextRow = form.rowBy(tag: "dealbreakers") else { return nil }
        guard let dealbreakers = dealbreakersRow.value else { return nil }
        
        guard let fromRow: IntRow = form.rowBy(tag: "from") else { return nil }
        guard let from = fromRow.value else { return nil }
        
        guard let toRow: IntRow = form.rowBy(tag: "to") else { return nil }
        guard let to = toRow.value else { return nil }
        
        guard let location = loc else { return nil }
        
        guard let uid = uid else { return nil }
                
        let ageRange = AgeRange(from: from, to: to)
        let details = Details(about: about, dealBreakers: dealbreakers, diet: Diet(rawValue: diet)!)
        let preferences = Preferences(ageRange: ageRange, lookingFor: lookingForArray)
        
        let data: [String: Any] = [
            "uid": uid,
            "name": name,
            "email": email,
            "age": age,
            "location": [
                "city": location.city,
                "country": location.country
            ],
            "preferences": [
                "ageRange": [
                    "from": preferences.ageRange.from,
                    "to": preferences.ageRange.to
                ],
                "lookingFor": preferences.lookingFor
            ],
            "details": [
                "about": details.about,
                "dealbreakers": details.dealBreakers,
                "diet": details.diet.rawValue
            ],
            "images": "",
            "isOnboarded": false,
            "isPremium": false,
            "isBanned": false,
            "isHidden": false,
            "likes": [],
            "dislikes": [],
            "created": Date().toString(dateFormat: "yyyy-MM-dd HH:mm:ss"),
            "blockedUsers": [],
            "chats": [],
            "likesLeft": 5,
            "cooldownTime": ""
        ]
        return data
    }
    
    func parseFormIntoDataForUpdatingUser() -> [String: Any]? {
        guard let nameRow: NameRow = form.rowBy(tag: "name") else { return nil }
        guard let name = nameRow.value else { return nil }
        
        guard let emailRow: EmailRow = form.rowBy(tag: "email") else { return nil }
        guard let email = emailRow.value else { return nil }
        
        guard let ageRow: IntRow = form.rowBy(tag: "age") else { return nil }
        guard let age = ageRow.value else { return nil }
        
        guard let aboutRow: TextRow = form.rowBy(tag: "about") else { return nil }
        guard let about = aboutRow.value else { return nil }
        
        guard let dietRow: PushRow<String> = form.rowBy(tag: "diet") else { return nil }
        guard let diet = dietRow.value else { return nil }
        
        guard let lookingForRow: MultipleSelectorRow<String> = form.rowBy(tag: "lookingFor") else { return nil }
        guard let lookingFor = lookingForRow.value else { return nil }
        var lookingForArray: [String] = []
        for l in lookingFor {
            if l == LookingFor.friendship.rawValue {
                lookingForArray.append(LookingFor.friendship.rawValue)
            } else if l == LookingFor.relationship.rawValue {
                lookingForArray.append(LookingFor.relationship.rawValue)
            } else if l == LookingFor.sex.rawValue {
                lookingForArray.append(LookingFor.sex.rawValue)
            }
        }
        
        guard let dealbreakersRow: TextRow = form.rowBy(tag: "dealbreakers") else { return nil }
        guard let dealbreakers = dealbreakersRow.value else { return nil }
        
        guard let fromRow: IntRow = form.rowBy(tag: "from") else { return nil }
        guard let from = fromRow.value else { return nil }
        
        guard let toRow: IntRow = form.rowBy(tag: "to") else { return nil }
        guard let to = toRow.value else { return nil }
        
        guard let location = loc else { return nil }
        
        let ageRange = AgeRange(from: from, to: to)
        let details = Details(about: about, dealBreakers: dealbreakers, diet: Diet(rawValue: diet)!)
        let preferences = Preferences(ageRange: ageRange, lookingFor: lookingForArray)
        
        let data: [String: Any] = [
            "name": name,
            "email": email,
            "age": age,
            "location": [
                "city": location.city,
                "country": location.country
            ],
            "preferences": [
                "ageRange": [
                    "from": preferences.ageRange.from,
                    "to": preferences.ageRange.to
                ],
                "lookingFor": preferences.lookingFor
            ],
            "details": [
                "about": details.about,
                "dealbreakers": details.dealBreakers,
                "diet": details.diet.rawValue
            ]
        ]
        return data
    }
    
    @objc func submit() {
        dismissKeyboard()
        if let currentUser = Auth.auth().currentUser {
            if let user = user {
                // Editing profile
                if form.validate().count > 0 {
                    Alertift.alert(title: "Ooopsie", message: "Check what fields are missiong or inacurrate.")
                        .action(.default("Okay"))
                        .show(on: self, completion: nil)
                } else {
                    if let data = parseFormIntoDataForUpdatingUser() {
                        FirestoreManager.shared.updateUser(uid: user.uid, data: data).then { (success) in
                            self.delegate?.refreshProfile()
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                }
            } else {
                // Onboarding
                if form.validate().count > 0 {
                    Alertift.alert(title: "Ooopsie", message: "Check what fields are missiong or inacurrate.")
                        .action(.default("Okay"))
                        .show(on: self, completion: nil)
                } else {
                    if onboardingContinues {
                        if let data = parseFormIntoData() {
                            FirestoreManager.shared.updateUser(uid: currentUser.uid, data: data).then { (success) in
                                let imageGalleryViewController = ImagesViewController()
                                self.navigationController?.pushViewController(imageGalleryViewController, animated: true)
                            }
                        } else {
                            if let data = parseFormIntoData() {
                                FirestoreManager.shared.addUser(uid: currentUser.uid, data: data).then { (success) in
                                    let imageGalleryViewController = ImagesViewController()
                                    self.navigationController?.pushViewController(imageGalleryViewController, animated: true)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func setupForm() {
        var rules = RuleSet<String>()
        rules.add(rule: RuleRequired())

        form
            
            +++ Section("About Me")
                
            <<< NameRow() { row in
                row.title = "Name"
                row.tag = "name"
                if let cu = user {
                    row.value = cu.name
                } else {
                    guard let name = name else { return }
                    row.value = name
                }
                row.add(ruleSet: rules)
                row.validationOptions = .validatesOnChangeAfterBlurred
            }
            .cellUpdate { cell, row in
                if !row.isValid {
                    cell.titleLabel?.textColor = .red
                }
            }
            
            <<< EmailRow() { row in
                row.title = "Email"
                row.tag = "email"
                if let cu = user {
                    row.value = cu.email
                } else {
                    guard let email = email else { return }
                    row.value = email
                }
                row.add(ruleSet: rules)
                row.add(rule: RuleEmail())
                row.validationOptions = .validatesOnChangeAfterBlurred
            }
            .cellUpdate { cell, row in
                if !row.isValid {
                    cell.titleLabel?.textColor = .red
                }
            }
            
            <<< IntRow() { row in
                row.title = "Age"
                row.tag = "age"
                row.add(rule: RuleRequired())
                if let cu = user {
                    row.value = cu.age
                }
            }
            
            
            <<< TextRow() { row in
                row.title = "About"
                row.tag = "about"
                row.add(rule: RuleRequired())
                if let cu = user {
                    row.value = cu.details.about
                }
            }
            
            <<< GooglePlacesTableRow() { row in
                row.title = "Location"
                row.tag = "location"
                if let cu = user {
                    row.value = GooglePlace(string: "\(cu.location.city), \(cu.location.country)")
                }
                row.add(ruleSet: RuleSet<GooglePlace>())
                row.validationOptions = .validatesOnChangeAfterBlurred
                }.onChange({ (row) in
                    row.value.map({ (place) in
                        switch place {
                        case .userInput(let value):
                            print(value)
                        case .prediction(let prediction):
                            self.loc = Location(city:  prediction.attributedPrimaryText.string, country: (prediction.attributedSecondaryText?.string)!)
                        }
                    })
                })
            
            <<< PushRow<String>() { row in
                row.title = "Diet"
                row.options = [Diet.vegan.rawValue, Diet.vegetarian.rawValue, Diet.omnivore.rawValue, Diet.other.rawValue]
                row.tag = "diet"
                row.add(rule: RuleRequired())
                if let cu = user {
                    row.value = cu.details.diet.rawValue
                }
            }
        
            +++ Section("Matching Preferences")
        
            <<< MultipleSelectorRow<String>() { row in
                row.title = "Looking for"
                row.add(rule: RuleRequired())
                row.options = [LookingFor.relationship.rawValue, LookingFor.friendship.rawValue, LookingFor.sex.rawValue]
                row.tag = "lookingFor"
                if let cu = user {
                    row.value = Set(cu.preferences.lookingFor)
                }
            }
            
            
            <<< TextRow() { row in
                row.title = "Dealbreakers"
                row.tag = "dealbreakers"
                row.add(rule: RuleRequired())
                if let cu = user {
                    row.value = cu.details.dealBreakers
                }
            }
        
            +++ Section("Prefered Age Range")
        
            <<< IntRow() { row in
                row.title = "From age"
                row.placeholder = ""
                row.tag = "from"
                row.add(rule: RuleRequired())
                if let cu = user {
                    row.value = cu.preferences.ageRange.from
                }
            }
            
            <<< IntRow() { row in
                row.title = "To age"
                row.placeholder = ""
                row.tag = "to"
                row.add(rule: RuleRequired())
                if let cu = user {
                    row.value = cu.preferences.ageRange.to
                }
            }
    }
}
