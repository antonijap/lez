//
//  FilterViewController.swift
//  Lez
//
//  Created by Antonija on 24/03/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import UIKit
import SnapKit
import Firebase
import Alertift
import Eureka

class FilterViewController: FormViewController {
    
    let closeButton = UIButton()
    
    var uid: String?
    var delegate: MatchViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupForm()
        self.setupNavigationBar()
        
        view.backgroundColor = .white
        
        if let cu = Auth.auth().currentUser {
            uid = cu.uid
            FirestoreManager.shared.fetchUser(uid: cu.uid).then { (user) in
                self.form.setValues(["from": user.preferences.ageRange.from, "to": user.preferences.ageRange.to, "lookingFor": Set(user.preferences.lookingFor)])
                self.tableView.reloadData()
            }
        }
    }
    
    func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(self.submit))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(self.dismissController))
        navigationItem.title = "Filter Users"
    }
    
    func setupCloseButton() {
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { (make) in
            make.size.equalTo(24)
            make.top.right.equalToSuperview().inset(24)
        }
        closeButton.snp.setLabel("CLOSE_BUTTON")
        closeButton.setImage(UIImage(named: "Close"), for: .normal)
        closeButton.addTarget(self, action: #selector(self.dismissController), for:.touchUpInside)
    }
    
    @objc func submit() {
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
        
        guard let fromRow: IntRow = form.rowBy(tag: "from") else { return }
        guard let from = fromRow.value else { return }
        
        guard let toRow: IntRow = form.rowBy(tag: "to") else { return }
        guard let to = toRow.value else { return }
        
        // Update profile in Firebase
        let data: [String: Any] = [
            "preferences": [
                "ageRange": [
                    "from": from,
                    "to": to
                ],
                "lookingFor": lookingForArray
            ]
        ]
        
        FirestoreManager.shared.updateUser(uid: uid!, data: data).then { (success) in
            if success {
                self.navigationController?.popViewController(animated: true)
            } else {
                Alertift.alert(title: "Ooopsie", message: "Updating profile failed. Please, try saving again.")
                    .action(.default("Okay"))
                    .show()
            }
        }
        
        delegate?.refreshKolodaData()
        dismissController()
    }
    
    @objc func dismissController() {
        dismiss(animated: true, completion: nil)
    }
    
    func setupForm() {
        form +++ Section("Matching Preferences")
            
            <<< MultipleSelectorRow<String>() { row in
                row.title = "Looking for"
                row.options = [LookingFor.relationship.rawValue, LookingFor.friendship.rawValue, LookingFor.sex.rawValue]
                row.tag = "lookingFor"
            }
            
            +++ Section("Prefered Age Range")
            
            <<< IntRow() { row in
                row.title = "From age"
                row.placeholder = ""
                row.tag = "from"
            }
            
            <<< IntRow() { row in
                row.title = "To age"
                row.placeholder = ""
                row.tag = "to"
        }
    }
}


