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

class SetupProfileViewController: FormViewController {
    
    var loc: Location?
    var name: String?
    var email: String?
    var uid: String?
    var currentUser: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupForm()
        setupNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let cu = currentUser {
            loc = Location(city: cu.location.city, country: cu.location.country)
            uid = cu.uid
            print(loc!)
        }
    }
    
    func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(self.submit))
        if let _ = currentUser {
            navigationItem.title = "Edit Profile"
        } else {
            navigationItem.title = "Setup Your Profile 1/2"
        }
    }
    
    func parseForm() -> User? {
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
        
        let ageRange = AgeRange(from: from, to: to)
        let details = Details(about: about, dealBreakers: dealbreakers, diet: Diet(rawValue: diet)!)
        let preferences = Preferences(ageRange: ageRange, lookingFor: lookingForArray)
        let user = User(uid: uid!, name: name, email: email, age: age, location: loc!, preferences: preferences, details: details)
        return user
    }
    
    @objc func submit() {
        if let cu = currentUser {
            if form.validate().count > 0 {
                Alertift.alert(title: "Ooopsie", message: "Check what fields are missiong or inacurrate.")
                    .action(.default("Okay"))
                    .show()
            } else {
                guard let user = parseForm() else { return }
                
                // Update profile in Firebase
                let data: [String: Any] = [
                    "name": user.name,
                    "email": user.email,
                    "age": user.age,
                    "location": [
                        "city": user.location.city,
                        "country": user.location.country
                    ],
                    "preferences": [
                        "ageRange": [
                            "from": user.preferences.ageRange.from,
                            "to": user.preferences.ageRange.to
                        ],
                        "lookingFor": user.preferences.lookingFor
                    ],
                    "details": [
                        "about": user.details.about,
                        "dealbreakers": user.details.dealBreakers,
                        "diet": user.details.diet.rawValue
                    ]
                ]

                FirestoreManager.shared.updateCurrentUser(uid: cu.uid, data: data).then { (success) in
                    if success {
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        Alertift.alert(title: "Ooopsie", message: "Updating profile failed. Please, try saving again.")
                            .action(.default("Okay"))
                            .show()
                    }
                }
            }
        } else {
            if form.validate().count > 0 {
                Alertift.alert(title: "Ooopsie", message: "Check what fields are missiong or inacurrate.")
                    .action(.default("Okay"))
                    .show()
            } else {
                guard let user = parseForm() else { return }
                let imageGalleryViewController = ImageGalleryViewController()
                imageGalleryViewController.user = user
                self.navigationController?.pushViewController(imageGalleryViewController, animated: true)
            }
        }
    }
    
    func setupForm() {
        print("setupForm")
        var rules = RuleSet<String>()
        rules.add(rule: RuleRequired())

        form
            
            +++ Section("About Me")
                
            <<< NameRow() { row in
                row.title = "Name"
                row.tag = "name"
                if let cu = currentUser {
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
                if let cu = currentUser {
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
                if let cu = currentUser {
                    row.value = cu.age
                }
            }
            
            
            <<< TextRow() { row in
                row.title = "About"
                row.tag = "about"
                if let cu = currentUser {
                    row.value = cu.details.about
                }
            }
            
            <<< GooglePlacesTableRow() { row in
                row.title = "Location"
                row.tag = "location"
                if let cu = currentUser {
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
                if let cu = currentUser {
                    row.value = cu.details.diet.rawValue
                }
            }
        
            +++ Section("Matching Preferences")
        
            <<< MultipleSelectorRow<String>() { row in
                row.title = "Looking for"
                row.options = [LookingFor.relationship.rawValue, LookingFor.friendship.rawValue, LookingFor.sex.rawValue]
                row.tag = "lookingFor"
                if let cu = currentUser {
                    row.value = Set(cu.preferences.lookingFor)
                }
            }
            
            
            <<< TextRow() { row in
                row.title = "Dealbreakers"
                row.tag = "dealbreakers"
                if let cu = currentUser {
                    row.value = cu.details.dealBreakers
                }
            }
        
            +++ Section("Prefered Age Range")
        
            <<< IntRow() { row in
                row.title = "From age"
                row.placeholder = ""
                row.tag = "from"
                if let cu = currentUser {
                    row.value = cu.preferences.ageRange.from
                }
            }
            
            <<< IntRow() { row in
                row.title = "To age"
                row.placeholder = ""
                row.tag = "to"
                if let cu = currentUser {
                    row.value = cu.preferences.ageRange.to
                }
            }
    }
}
