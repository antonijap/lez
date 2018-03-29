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

class SetupProfileViewController: FormViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        hideKeyboardWhenTappedAround()
        setupForm()
        setupNavigationBar()
    }
    
    func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(self.submit))
        navigationItem.title = "Setup Your Profile"
    }
    
    @objc func submit() {
        if form.validate().count > 0 {
            self.showOkayModal(messageTitle: "Please check all fields", messageAlert: "", messageBoxStyle: .alert, alertActionStyle: .default, completionHandler: {})
        } else {
            
        }
        
        let nameRow: TextRow? = form.rowBy(tag: "name")
        let name = nameRow?.value
        print(name)
//        let nameRow: TextRow? = form.rowBy(tag: "name")
//        let name = nameRow?.value
//        let emailRow: TextRow = form.rowBy(tag: "email")!
//        let email = emailRow.value
//        let ageRow: IntRow = form.rowBy(tag: "age")!
//        let age = ageRow.value)!
//        let aboutRow: TextRow = form.rowBy(tag: "about")!
//        let about = aboutRow.value
//        let locationRow: TextRow = form.rowBy(tag: "location")!
//        let location = locationRow.value
//        let lookingForRow: TextRow = form.rowBy(tag: "lookingFor")!
//        let lookingFor = lookingForRow.value
//        let fromAgeRow: TextRow = form.rowBy(tag: "fromAge")!
//        let fromAge = Int((fromAgeRow.value)!)
//        let toAgeRow: TextRow = form.rowBy(tag: "toAge")!
//        let toAge = Int((toAgeRow.value)!)
//        let dealBreakersRow: TextRow = form.rowBy(tag: "dealbreakers")!
//        let dealBreakers = dealBreakersRow.value
//        let dietRow: TextRow = form.rowBy(tag: "diet")!
//        let diet = dietRow.value
//
//        let matchingPreferences = MatchingPreferences(ageRange: (fromAge!, toAge!), location: location!, lookingFor: [LookingFor(rawValue: lookingFor!)!])
//        let details = Details(about: about!, dealBreakers: dealBreakers!, diet: Diet(rawValue: diet!)!)
//        let user = User(id: 875438957, name: name!, email: email!, age: age!, location: location!, matchingPreferences: matchingPreferences, details: details, images: Images(imageURLs: ["https://picsum.photos/1000/1000", "https://picsum.photos/1000/1000"]))
//
//        print(user)
//        let matchViewController = MatchViewController()
//        matchViewController.currentUser = user
//        let navigationController = UINavigationController(rootViewController: matchViewController)
//        present(navigationController, animated: true, completion: nil)
    }
    
    func setupForm() {
        var rules = RuleSet<String>()
        rules.add(rule: RuleRequired())
        
        form
            
            +++ Section("About Me")
                
            <<< NameRow() { row in
                row.title = "Name"
                row.tag = "name"
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
            }
            
            
            <<< TextRow() { row in
                row.title = "About"
                row.tag = "about"
            }
            
            <<< GooglePlacesTableRow() { row in
                row.title = "Location"
                row.tag = "location"
                row.add(ruleSet: RuleSet<GooglePlace>())
                row.validationOptions = .validatesOnChangeAfterBlurred
                row.cell.textLabel?.textColor = .black
            }
            
            <<< PushRow<String>() { row in
                row.title = "Diet"
                row.options = ["Vegan", "Vegetarian", "Omnivore", "Other"]
                row.tag = "diet"
            }
        
            +++ Section("Matching Preferences")
        
            <<< MultipleSelectorRow<String>() { row in
                row.title = "Looking for"
                row.options = ["Relationship", "Friendship", "Sex"]
                row.tag = "lookingFor"
            }
            
            <<< TextRow() { row in
                row.title = "Dealbreakers"
                row.tag = "dealbreakers"
            }
        
            +++ Section("Prefered Age Range")
        
            <<< IntRow(){ row in
                row.title = "From age"
                row.placeholder = ""
                row.tag = "fromAge"
            }
            
            <<< IntRow(){ row in
                row.title = "To age"
                row.placeholder = ""
                row.tag = "toAge"
            }
        
    }
}
