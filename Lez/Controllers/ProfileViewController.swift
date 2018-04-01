//
//  ProfileViewController.swift
//  Lez
//
//  Created by Antonija on 31/03/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import UIKit
import Firebase
import SnapKit

class ProfileViewController: UIViewController {

    var profileImageView: UIImageView!
    var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        profileImageView = UIImageView()
        view.addSubview(profileImageView)
        profileImageView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin).inset(16)
            make.size.equalTo(140)
            make.centerX.equalToSuperview()
        }
        profileImageView.backgroundColor = .yellow

        label = UILabel()
        view.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        label.text = "Profile"
        
        let user = Auth.auth().currentUser
        if let user = user {
            let email = user.email
            label.text = "Profile: \(email!), \(user.displayName!)"
        }
        
        let logoutButton = UIButton()
        view.addSubview(logoutButton)
        logoutButton.snp.makeConstraints { (make) in
            make.top.equalTo(label.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().inset(40)
            make.height.equalTo(30)
        }
        logoutButton.backgroundColor = .clear
        logoutButton.setTitleColor(.blue, for: .normal)
        logoutButton.setTitle("Logout", for: .normal)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(logoutTapped(_:)))
        logoutButton.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func logoutTapped(_ sender: UIButton) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            print("Signed out")
            let registerViewController = RegisterViewController()
            let navigationController = UINavigationController(rootViewController: registerViewController)
            self.present(navigationController, animated: false, completion: nil)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    func passUser(image: UIImage) {
        print("TAP")
        print(image)
        profileImageView.image = image
    }
    
}
