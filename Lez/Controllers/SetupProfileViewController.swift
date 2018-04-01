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
    
    var location: Location!
    var name: String?
    var email: String?
    var uid: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupForm()
        setupNavigationBar()
    }
    
    func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(self.submit))
        navigationItem.title = "Setup Your Profile 1/2"
    }
    
    @objc func submit() {
        if form.validate().count > 0 {
            Alertift.alert(title: "Ooopsie", message: "Check what fields are missiong or inacurrate.")
                .action(.default("Okay"))
                .show()
        } else {
            guard let nameRow: NameRow = form.rowBy(tag: "name") else { return }
            guard let name = nameRow.value else { return }
            
            guard let emailRow: EmailRow = form.rowBy(tag: "email") else { return }
            guard let email = emailRow.value else { return }
            
            guard let ageRow: IntRow = form.rowBy(tag: "age") else { return }
            guard let age = ageRow.value else { return }
            
            guard let aboutRow: TextRow = form.rowBy(tag: "about") else { return }
            guard let about = aboutRow.value else { return }
            
            guard let dietRow: PushRow<String> = form.rowBy(tag: "diet") else { return }
            guard let diet = dietRow.value else { return }
            
            guard let lookingForRow: MultipleSelectorRow<String> = form.rowBy(tag: "lookingFor") else { return }
            guard let lookingFor = lookingForRow.value else { return }
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
            
            guard let dealbreakersRow: TextRow = form.rowBy(tag: "dealbreakers") else { return }
            guard let dealbreakers = dealbreakersRow.value else { return }
            
            guard let fromRow: IntRow = form.rowBy(tag: "from") else { return }
            guard let from = fromRow.value else { return }
            
            guard let toRow: IntRow = form.rowBy(tag: "to") else { return }
            guard let to = toRow.value else { return }
            
            let ageRange = AgeRange(from: from, to: to)
            let details = Details(about: about, dealBreakers: dealbreakers, diet: Diet(rawValue: diet)!)
            let preferences = Preferences(ageRange: ageRange, lookingFor: lookingForArray)
            let user = User(uid: uid!, name: name, email: email, age: age, location: location, preferences: preferences, details: details)
            
            let imageGalleryViewController = ImageGalleryViewController()
            imageGalleryViewController.user = user
            self.navigationController?.pushViewController(imageGalleryViewController, animated: true)
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
                guard let name = name else { return }
                row.value = name
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
                guard let email = email else { return }
                row.value = email
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
                row.value = 28
            }
            
            
            <<< TextRow() { row in
                row.title = "About"
                row.tag = "about"
                row.value = "I am from Croatia and I like cats."
            }
            
            <<< GooglePlacesTableRow() { row in
                row.title = "Location"
                row.tag = "location"
                row.add(ruleSet: RuleSet<GooglePlace>())
                row.validationOptions = .validatesOnChangeAfterBlurred
                }.onChange({ (row) in
                    row.value.map({ (place) in
                        switch place {
                        case .userInput(let value):
                            print(value)
                        case .prediction(let prediction):
                            self.location = Location(city:  prediction.attributedPrimaryText.string, country: (prediction.attributedSecondaryText?.string)!)
                        }
                    })
                })
            
            <<< PushRow<String>() { row in
                row.title = "Diet"
                row.options = [Diet.vegan.rawValue, Diet.vegetarian.rawValue, Diet.omnivore.rawValue, Diet.other.rawValue]
                row.tag = "diet"
                row.value = Diet.vegan.rawValue
            }
        
            +++ Section("Matching Preferences")
        
            <<< MultipleSelectorRow<String>() { row in
                row.title = "Looking for"
                row.options = [LookingFor.relationship.rawValue, LookingFor.friendship.rawValue, LookingFor.sex.rawValue]
                row.tag = "lookingFor"
                row.value = [LookingFor.relationship.rawValue, LookingFor.friendship.rawValue]
            }
            
            
            <<< TextRow() { row in
                row.title = "Dealbreakers"
                row.tag = "dealbreakers"
                row.value = "Stupid people"
            }
        
            +++ Section("Prefered Age Range")
        
            <<< IntRow() { row in
                row.title = "From age"
                row.placeholder = ""
                row.tag = "from"
                row.value = 28
            }
            
            <<< IntRow() { row in
                row.title = "To age"
                row.placeholder = ""
                row.tag = "to"
                row.value = 33
            }
    }
    
}
