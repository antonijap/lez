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

final class FilterViewController: FormViewController {

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
        if let user = user {
            form.setValues(["lookingFor": Set(user.preferences.lookingFor)])
            tableView.reloadData()
        }
    }

    func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(self.submit))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(self.dismissController))
        navigationItem.title = "Filter Results"
        navigationController?.navigationBar.backgroundColor = .white
        navigationController?.navigationBar.setBackgroundImage(#imageLiteral(resourceName: "White"), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layer.masksToBounds = false
        navigationController?.navigationBar.layer.shadowColor = UIColor(red:0.90, green:0.90, blue:0.90, alpha:1.00).cgColor
        navigationController?.navigationBar.layer.shadowOpacity = 0.8
        navigationController?.navigationBar.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        navigationController?.navigationBar.layer.shadowRadius = 4
    }

    func setupCloseButton() {
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.size.equalTo(24)
            make.top.right.equalToSuperview().inset(24)
        }
        closeButton.snp.setLabel("CLOSE_BUTTON")
        closeButton.setImage(#imageLiteral(resourceName: "Close"), for: .normal)
        closeButton.addTarget(self, action: #selector(self.dismissController), for: .primaryActionTriggered)
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

        guard let showAllLesbians: SwitchRow = form.rowBy(tag: "toggleAll")  else { return }
        DefaultsManager.shared.saveToggleAllLesbians(value: showAllLesbians.value!)

        FirestoreManager.shared.updateUser(uid: user!.uid, data: data).then { success in
            guard success else {
                Alertift.alert(title: "Ooopsie", message: "Updating profile failed. Please, try saving again.")
                .action(.default("Okay"))
                .show()
                return
            }
            self.navigationController?.popViewController(animated: true)
        }
        delegate?.refreshTableView()
        AnalyticsManager.shared.logEvent(name: AnalyticsEvents.userAdjustedFilters, user: user!)
        dismissController()
    }
    
    @objc func dismissController() {
        dismiss(animated: true)
    }

    @objc func multipleSelectorDone(_ item:UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }

    func setupForm() {
        form +++ Section("Matching Preferences")
            <<< MultipleSelectorRow<String>() { row in
                row.title = "Looking for"
                row.options = [LookingFor.relationship.rawValue, LookingFor.friendship.rawValue, LookingFor.sex.rawValue]
                row.tag = "lookingFor"
            }.onPresent { from, to in
                let rightButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.multipleSelectorDone(_:)))
                to.navigationItem.rightBarButtonItem = rightButton
            }
            <<< SwitchRow() { row in
                row.tag = "toggleAll"
                row.title = "Show all lesbians"
                row.value = DefaultsManager.shared.fetchToggleAllLesbians()
            }
            +++ Section("Prefered Age Range")
            <<< RangeSliderRow() { row in
                row.tag = "agePreference"
                }.cellSetup({ cell, row in
                    cell.slider.selectedMaxValue = CGFloat(self.user!.preferences.ageRange.to)
                    cell.slider.selectedMinValue = CGFloat(self.user!.preferences.ageRange.from)
                })
    }
}
