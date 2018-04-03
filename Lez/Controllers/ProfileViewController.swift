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
import moa
import SkeletonView

class RoundProfileImageView: UIImageView {
    
    override func layoutSubviews() {
        backgroundColor = .white
        layer.borderWidth = 1
        layer.borderColor = UIColor(red:0.92, green:0.92, blue:0.92, alpha:1.00).cgColor
        layer.cornerRadius = frame.size.width / 2
        layer.masksToBounds = true
        contentMode = .scaleAspectFill
        clipsToBounds = true
    }
}

class ProfileViewController: UIViewController {

    var profileImageView: UIImageView!
    var label: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.showAnimatedSkeleton()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        profileImageView = RoundProfileImageView()
        profileImageView.isSkeletonable = true
        profileImageView.snp.setLabel("Profile Image View")
        view.addSubview(profileImageView)
        profileImageView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin).inset(48)
            make.size.equalTo(140)
            make.centerX.equalToSuperview()
        }
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true

        label = UILabel()
        view.addSubview(label)
        label.snp.setLabel("Label")
        label.isSkeletonable = true
        label.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalToSuperview().inset(48)
        }
        label.text = "Fetching user, please wait..."
        label.textAlignment = .center

        let logoutButton = UIButton()
        view.addSubview(logoutButton)
        logoutButton.isSkeletonable = true
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

        guard let uid = DefaultsManager.shared.fetchUID() else { return }
        FirestoreManager.shared.fetchCurrentUser(uid: uid).then { (user) in
            guard let profileImageURL = user.images?.first else {
                print("Can't download profileImageURL.")
                return

            }
            self.profileImageView.moa.url = profileImageURL
            self.profileImageView.moa.onSuccess = { image in
                self.view.stopSkeletonAnimation()
                self.view.hideSkeleton()
                let user = Auth.auth().currentUser
                if let user = user {
                    let email = user.email
                    self.label.text = "Profile: \(email!), \(user.displayName!)"
                }
                self.profileImageView.image = image
                return image
            }
        }
    }
    
    @objc func logoutTapped(_ sender: UIButton) {
        let firebaseAuth = Auth.auth()
        do {
            
            // Add Facebook logout
            try firebaseAuth.signOut()
            print("Signed out")
            let registerViewController = RegisterViewController()
            let navigationController = UINavigationController(rootViewController: registerViewController)
            self.present(navigationController, animated: false, completion: nil)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
}
