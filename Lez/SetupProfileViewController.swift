//
//  SetupProfileViewController.swift
//  Lez
//
//  Created by Antonija Pek on 25/03/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import UIKit
import SwiftForms

class SetupProfileViewController: FormViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        loadForm()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Submit", style: .plain, target: self, action: #selector(self.submit))
        navigationItem.title = "Setup Your Profile"
        hideKeyboardWhenTappedAround()
    }
    
    @objc func submit() {
        print("Submit...")
        for i in form.formValues() {
           print(i.value)
        }
    }
    
    func loadForm() {
        let form = FormDescriptor()
        
        let section1 = FormSectionDescriptor(headerTitle: "About You", footerTitle: "")
        
        var row = FormRowDescriptor(tag: "name", type: .email, title: "Name")
        section1.rows.append(row)
        
        row = FormRowDescriptor(tag: "age", type: .number, title: "Age")
        section1.rows.append(row)
        
        row = FormRowDescriptor(tag: "location", type: .text, title: "Location")
        section1.rows.append(row)
        
        // Define second section
        let section2 = FormSectionDescriptor(headerTitle: "Your Matching Preferences", footerTitle: "")
        
        row = FormRowDescriptor(tag: "reason", type: .multipleSelector, title: "What are you looking for?")
        row.configuration.selection.options = ([0, 1, 2] as [Int]) as [AnyObject]
        row.configuration.selection.allowsMultipleSelection = true
        row.configuration.selection.optionTitleClosure = { value in
            guard let option = value as? Int else { return "" }
            switch option {
            case 0:
                return "Relationship"
            case 1:
                return "Friendship"
            case 2:
                return "Sex"
            default:
                return ""
            }
        }
        section2.rows.append(row)
        
        form.sections = [section1, section2]
        self.form = form
    }
}
