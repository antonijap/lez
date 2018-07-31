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
import CoreLocation

final class UserProfileFormViewController: FormViewController {

    var loc: Location?
    var name: String?
    var email: String?
    var uid: String?
    var user: User?
    var profileViewControllerDelegate: ProfileViewControllerDelegate?
    var handle: AuthStateDidChangeListenerHandle?
    var onboardingContinues = false
    var isEmailDisabled = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()

        guard let user = user else { setupBasicForm(); return }
        setupEditForm(uid: user.uid)
        Firestore.firestore().collection("users").document(user.uid).getDocument { documentSnapshot, error in
            guard let document = documentSnapshot else { print("Error fetching document: \(error!)"); return }
            guard let data = document.data() else { return }
            guard let isOnboarded = data["isOnboarded"] as? Bool else { print("Problem with parsing isOnboarded."); return }
            if isOnboarded {
                FirestoreManager.shared.fetchUser(uid: user.uid).then { user in
                    self.user = user
                    self.loc = Location(city: user.location.city, country: user.location.country)
                    self.uid = user.uid
                }
            }
            self.onboardingContinues = true
        }
    }

    func setupNavigationBar() {
        navigationController?.view.backgroundColor = .white
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(self.submit))
        if let _ = user { // There is user show back button
            navigationItem.title = "Your Profile"
        } else {
            navigationItem.title = "Setup Profile"
//            navigationItem.setHidesBackButton(true, animated: true)
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
        guard let location = loc else { return nil }
        guard let currentUser = Auth.auth().currentUser else { return nil }
        guard let agePreferenceObj: RangeSliderRow = form.rowBy(tag: "agePreference") else { return nil }

        let data: [String: Any] = [
            "uid": currentUser.uid,
            "name": name,
            "email": email,
            "age": age,
            "location": [
                "city": location.city,
                "country": location.country
            ],
            "preferences": [
                "ageRange": [
                    "from": Int(agePreferenceObj.cell.slider.selectedMinValue),
                    "to": Int(agePreferenceObj.cell.slider.selectedMaxValue)
                ],
                "lookingFor": lookingForArray
            ],
            "details": [
                "about": about,
                "dealbreakers": dealbreakers,
                "diet": diet
            ],
            "images": "",
            "isOnboarded": false,
            "isPremium": false,
            "isBanned": false,
            "isHidden": false,
            "likes": [],
            "created": Date().toString(dateFormat: "yyyy-MM-dd HH:mm:ss"),
            "blockedUsers": [],
            "chats": [],
            "likesLeft": 5,
            "cooldownTime": "",
            "isManuallyPromoted": false
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
        guard let location = loc else { return nil }
        guard let currentUser = Auth.auth().currentUser else { return nil }
        guard let agePreferenceObj: RangeSliderRow = form.rowBy(tag: "agePreference") else { return nil }
        let data: [String: Any] = [
            "uid": currentUser.uid,
            "name": name,
            "email": email,
            "age": age,
            "location": [
                "city": location.city,
                "country": location.country
            ],
            "preferences": [
                "ageRange": [
                    "from": Int(agePreferenceObj.cell.slider.selectedMinValue),
                    "to": Int(agePreferenceObj.cell.slider.selectedMaxValue)
                ],
                "lookingFor": lookingForArray
            ],
            "details": [
                "about": about,
                "dealbreakers": dealbreakers,
                "diet": diet
            ]
        ]
        return data
    }

    @objc func submit() {
        dismissKeyboard()
        if let _ = Auth.auth().currentUser {
            if let user = user {
                // Editing profile
                if form.validate().count > 0 {
                    Alertift.alert(title: "Ooopsie", message: "Check what fields are missing or inacurrate.")
                        .action(.default("Okay"))
                        .show(on: self)
                } else {
                    if let data = parseFormIntoDataForUpdatingUser() {
                        FirestoreManager.shared.updateUser(uid: user.uid, data: data).then { success in
                            AnalyticsManager.shared.logEvent(name: AnalyticsEvents.userEditedProfile, user: user)
                            DefaultsManager.shared.savePreferedLocation(value: user.location.city)
                            self.profileViewControllerDelegate?.refreshProfile()
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                }
            } else {
                // Onboarding
                if form.validate().count > 0 {
                    Alertift.alert(title: "Ooopsie", message: "Check what fields are missiong or inacurrate.")
                        .action(.default("Okay"))
                        .show(on: self)
                } else {
                    if onboardingContinues {
                        if let data = parseFormIntoData() {
                            let imagesViewController = ImagesViewController()
                            imagesViewController.data = data
                            self.navigationItem.hidesBackButton = true
                            self.navigationController?.pushViewController(imagesViewController, animated: true)                        }
                    } else {
                        if let data = parseFormIntoData() {
                            let imagesViewController = ImagesViewController()
                            imagesViewController.data = data
                            self.navigationItem.hidesBackButton = true
                            self.navigationController?.pushViewController(imagesViewController, animated: true)
                        }
                    }
                }
            }
        } else {
            Alertift.alert(title: "Error happened", message: "Random error happened, please try to login again.")
                .action(.default("Okay"))
                .show(on: self)
        }
    }

    func setupBasicForm() {
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
            .cellUpdate { cell, row in if !row.isValid { cell.titleLabel?.textColor = .red } }
            <<< EmailRow() { row in
                row.title = "Email"
                row.tag = "email"
                if let cu = user {
                    row.value = cu.email
                } else {
                    guard let email = email else { return }
                    row.value = email
                }
                if isEmailDisabled {
                    row.disabled = true
                } else {
                    row.add(ruleSet: rules)
                    row.add(rule: RuleEmail())
                    row.validationOptions = .validatesOnChangeAfterBlurred
                }
            }
            .cellUpdate { cell, row in if !row.isValid { cell.titleLabel?.textColor = .red } }
            <<< IntRow() { row in
                row.title = "Age"
                row.tag = "age"
                row.add(rule: RuleRequired())
                if let cu = user { row.value = cu.age }
            }
            <<< TextRow() { row in
                row.title = "About"
                row.tag = "about"
                row.add(rule: RuleRequired())
                if let cu = user { row.value = cu.details.about }
            }
            <<< GooglePlacesTableRow() { row in
                row.title = "Location"
                row.tag = "location"
                if let cu = user { row.value = GooglePlace(string: "\(cu.location.city), \(cu.location.country)") }
                row.add(ruleSet: RuleSet<GooglePlace>())
                row.validationOptions = .validatesOnChangeAfterBlurred
                }.onChange({ row in
                    row.value.map({ place in
                        switch place {
                        case .userInput(let value):
                            print(value)
                        case .prediction(let prediction):
                            self.loc = Location(city: prediction.attributedPrimaryText.string,
                                                country: (prediction.attributedSecondaryText?.string)!)
                        }
                    })
                })
            <<< PushRow<String>() { row in
                row.title = "Diet"
                row.options = [Diet.vegan.rawValue, Diet.vegetarian.rawValue, Diet.omnivore.rawValue, Diet.other.rawValue]
                row.tag = "diet"
                row.add(rule: RuleRequired())
                if let cu = user { row.value = cu.details.diet.rawValue }
            }
            +++ Section("Matching Preferences")
            <<< MultipleSelectorRow<String>() { row in
                row.title = "Looking for"
                row.add(rule: RuleRequired())
                row.options = [LookingFor.relationship.rawValue, LookingFor.friendship.rawValue, LookingFor.sex.rawValue]
                row.tag = "lookingFor"
                if let cu = user { row.value = Set(cu.preferences.lookingFor) }
            }
            <<< TextRow() { row in
                row.title = "Dealbreakers"
                row.tag = "dealbreakers"
                row.add(rule: RuleRequired())
                if let cu = user { row.value = cu.details.dealBreakers }
            }
            +++ Section("Prefered Age Range")
            <<< RangeSliderRow() { row in
                row.tag = "agePreference"
                }.cellSetup({ (cell, row) in
                    if let user = self.user {
                        cell.slider.selectedMaxValue = CGFloat(user.preferences.ageRange.to)
                        cell.slider.selectedMinValue = CGFloat(user.preferences.ageRange.from)
                    }
            })
    }
    
    func setupEditForm(uid: String) {
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
                .cellUpdate { cell, row in if !row.isValid { cell.titleLabel?.textColor = .red } }
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
                .cellUpdate { cell, row in if !row.isValid { cell.titleLabel?.textColor = .red } }
            <<< IntRow() { row in
                row.title = "Age"
                row.tag = "age"
                row.add(rule: RuleRequired())
                if let cu = user { row.value = cu.age }
            }
            <<< TextRow() { row in
                row.title = "About"
                row.tag = "about"
                row.add(rule: RuleRequired())
                if let cu = user { row.value = cu.details.about }
            }
            <<< GooglePlacesTableRow() { row in
                row.title = "Location"
                row.tag = "location"
                if let cu = user { row.value = GooglePlace(string: "\(cu.location.city), \(cu.location.country)") }
                row.add(ruleSet: RuleSet<GooglePlace>())
                row.validationOptions = .validatesOnChangeAfterBlurred
                }.onChange({ (row) in
                    row.value.map({ (place) in
                        switch place {
                        case .userInput(let value):
                            print(value)
                        case .prediction(let prediction):
                            self.loc = Location(city:  prediction.attributedPrimaryText.string,
                                                country: (prediction.attributedSecondaryText?.string)!)
                        }
                    })
                })
            <<< PushRow<String>() { row in
                row.title = "Diet"
                row.options = [Diet.vegan.rawValue, Diet.vegetarian.rawValue, Diet.omnivore.rawValue, Diet.other.rawValue]
                row.tag = "diet"
                row.add(rule: RuleRequired())
                if let cu = user { row.value = cu.details.diet.rawValue }
            }
            +++ Section("Matching Preferences")
            <<< MultipleSelectorRow<String>() { row in
                row.title = "Looking for"
                row.add(rule: RuleRequired())
                row.options = [LookingFor.relationship.rawValue, LookingFor.friendship.rawValue, LookingFor.sex.rawValue]
                row.tag = "lookingFor"
                if let cu = user { row.value = Set(cu.preferences.lookingFor) }
            }
            <<< TextRow() { row in
                row.title = "Dealbreakers"
                row.tag = "dealbreakers"
                row.add(rule: RuleRequired())
                if let cu = user { row.value = cu.details.dealBreakers }
            }
            +++ Section("Prefered Age Range")
            <<< RangeSliderRow() { row in
                row.tag = "agePreference"
                }.cellSetup({ (cell, row) in
                    if let user = self.user {
                        cell.slider.selectedMaxValue = CGFloat(user.preferences.ageRange.to)
                        cell.slider.selectedMinValue = CGFloat(user.preferences.ageRange.from)
                    }
            })
            +++ Section("Danger Area")
            <<< ButtonRow() { row in
                row.tag = "delete"
                row.title = "Delete Account"
                }.onCellSelection({ (cell, row) in
                    Alertift.alert(title: "Last Warning", message: "This action is irreversable.")
                        .action(.destructive("Delete Account"), handler: { (_, _, _) in
                            FirestoreManager.shared.deleteUser(uid: uid).then({ (success) in
                                if success {
                                    do {
                                        AnalyticsManager.shared.logEvent(name: AnalyticsEvents.userDeletedAccount, user: self.user!)
                                        try Auth.auth().signOut()
                                        self.tabBarController?.selectedIndex = 0
                                    } catch let signOutError { print ("Error signing out: %@", signOutError) }
                                }
                            })
                            
                            
                        })
                        .action(Alertift.Action.cancel("Cancel"))
                        .show(on: self)
                })
    }
}
