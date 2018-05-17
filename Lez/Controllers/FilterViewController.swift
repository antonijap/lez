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
    var user: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupForm()
        setupNavigationBar()
        tableView.separatorStyle = .none
        view.backgroundColor = .white
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let user = user {
            let ageRange = AgeRange(from: user.preferences.ageRange.from, to: user.preferences.ageRange.to)
            form.setValues(["lookingFor": Set(user.preferences.lookingFor)])
            tableView.reloadData()
        }
    }
    
    func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(self.submit))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(self.dismissController))
        navigationItem.title = "Filter Results"
        navigationController?.navigationBar.backgroundColor = .white
        navigationController?.navigationBar.setBackgroundImage(UIImage(named: "White"), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layer.masksToBounds = false
        navigationController?.navigationBar.layer.shadowColor = UIColor(red:0.90, green:0.90, blue:0.90, alpha:1.00).cgColor
        navigationController?.navigationBar.layer.shadowOpacity = 0.8
        navigationController?.navigationBar.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        navigationController?.navigationBar.layer.shadowRadius = 4
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
        
        guard let agePreferenceObj: RangeSliderRow = form.rowBy(tag: "agePreference") else { return }
        let data: [String: Any] = [
            "preferences": [
                "ageRange": [
                    "from": Int(agePreferenceObj.cell.slider.selectedMinValue),
                    "to": Int(agePreferenceObj.cell.slider.selectedMaxValue)
                ],
                "lookingFor": lookingForArray
            ]
        ]
        FirestoreManager.shared.updateUser(uid: user!.uid, data: data).then { (success) in
            if success {
                self.navigationController?.popViewController(animated: true)
            } else {
                Alertift.alert(title: "Ooopsie", message: "Updating profile failed. Please, try saving again.")
                    .action(.default("Okay"))
                    .show()
            }
        }
        delegate?.refreshTableView()
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
            
//            <<< IntRow() { row in
//                row.title = "From age"
//                row.placeholder = ""
//                row.tag = "from"
//            }
            
            <<< RangeSliderRow() { row in
                row.tag = "agePreference"
                }.cellSetup({ (cell, row) in
                    cell.slider.selectedMaxValue = CGFloat(self.user!.preferences.ageRange.to)
                    cell.slider.selectedMinValue = CGFloat(self.user!.preferences.ageRange.from)
                })
            
//            <<< IntRow() { row in
//                row.title = "To age"
//                row.placeholder = ""
//                row.tag = "to"
        
    }
}


