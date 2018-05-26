//
//  RegisterViewController.swift
//  Lez
//
//  Created by Antonija on 30/03/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin
import Firebase
import JGProgressHUD
import TwitterKit

class RegisterViewController: UIViewController {
    
    private let facebookLoginButton = UIButton()
    private let twitterLoginButton = UIButton()
    private let hud = JGProgressHUD(style: .dark)
    private let backgroundImageView = UIImageView()
    private let bottomButtonsContainer = UIView()
    private let privacyPolicyButton = UIButton()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        stopSpinner()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupButtons()
        setupPrivacyPolicy()
        if let currentUser = Auth.auth().currentUser {
            let setupProfileViewController = UserProfileFormViewController()
            setupProfileViewController.name = currentUser.displayName!
            setupProfileViewController.email = currentUser.email!
            setupProfileViewController.uid = currentUser.uid
            navigationItem.hidesBackButton = true
            navigationController?.pushViewController(setupProfileViewController, animated: true)
        }
    }
    
    private func setupPrivacyPolicy() {
        view.addSubview(privacyPolicyButton)
        privacyPolicyButton.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().inset(16)
            make.centerX.equalToSuperview()
        }
        privacyPolicyButton.setTitle("Privacy Policy", for: .normal)
        privacyPolicyButton.setTitleColor(.gray, for: .normal)
        privacyPolicyButton.addTarget(self, action: #selector(self.privacyPolicyButtontapped), for: .touchUpInside)
        privacyPolicyButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .regular)
    }
    
    @objc private func privacyPolicyButtontapped() {
        if let url = URL(string: "https://www.iubenda.com/privacy-policy/89963959") {
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    
    private func setupBackground() {
        view.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        backgroundImageView.image = UIImage(named: "Register")
        backgroundImageView.contentMode = .scaleAspectFill
    }
    
    private func startSpinner() {
        hud.textLabel.text = "Logging in"
        hud.show(in: view)
        hud.interactionType = .blockAllTouches
        hud.detailTextLabel.font = UIFont.systemFont(ofSize: 9.0, weight: .regular)
    }
    
    private func stopSpinner() {
        hud.dismiss(animated: true)
    }

    private func setupButtons() {
        view.addSubview(twitterLoginButton)
        twitterLoginButton.setTitle("Login with Twitter", for: .normal)
        twitterLoginButton.addTarget(self, action: #selector(self.twitterButtonTapped), for:.touchUpInside)
        twitterLoginButton.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(48)
            make.bottom.equalToSuperview().inset(100)
            make.height.equalTo(48)
        }
        twitterLoginButton.backgroundColor = UIColor(red:0.30, green:0.62, blue:0.93, alpha:1.00)
        twitterLoginButton.layer.cornerRadius = 48 / 2
        
        facebookLoginButton.setTitle("Login with Facebook", for: .normal)
        facebookLoginButton.addTarget(self, action: #selector(self.facebookButtonTapped), for:.touchUpInside)
        view.addSubview(facebookLoginButton)
        facebookLoginButton.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(48)
            make.bottom.equalTo(twitterLoginButton.snp.top).inset(-8)
            make.height.equalTo(48)
        }
        facebookLoginButton.backgroundColor = UIColor(red:0.28, green:0.37, blue:0.60, alpha:1.00)
        facebookLoginButton.layer.cornerRadius = 48 / 2
    }
    
    @objc func twitterButtonTapped() {
        TWTRTwitter.sharedInstance().logIn(completion: { (session, error) in
            if let session = session {
                self.startSpinner()
                let credential = TwitterAuthProvider.credential(withToken: session.authToken, secret: session.authTokenSecret)
                Auth.auth().signInAndRetrieveData(with: credential) { (user, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    // User is signed in
                    guard let currentUser = user else { return }
                    FirestoreManager.shared.checkIfUserExists(uid: currentUser.user.uid).then({ (exists) in
                        if exists {
                            FirestoreManager.shared.fetchUser(uid: currentUser.user.uid).then { (user) in
                                if user.isOnboarded {
                                    self.stopSpinner()
                                    self.dismiss(animated: true, completion: nil)
                                } else {
                                    let userProfileFormViewController = UserProfileFormViewController()
                                    userProfileFormViewController.name = currentUser.user.displayName!
                                    if let email = currentUser.user.email {
                                        userProfileFormViewController.email = email
                                    }
                                    userProfileFormViewController.uid = currentUser.user.uid
                                    self.navigationItem.setHidesBackButton(true, animated: true)
                                    self.navigationController?.pushViewController(userProfileFormViewController, animated: true)
                                }
                            }
                        } else {
                            let userProfileFormViewController = UserProfileFormViewController()
                            userProfileFormViewController.name = currentUser.user.displayName!
                            userProfileFormViewController.uid = currentUser.user.uid
                            self.navigationItem.setHidesBackButton(true, animated: true)
                            self.navigationController?.pushViewController(userProfileFormViewController, animated: true)
                        }
                    })
                }
            } else {
                print(error.debugDescription)
            }
        })
    }
   
    @objc func facebookButtonTapped() {
        startSpinner()
        let loginManager = LoginManager()
        loginManager.logOut()
        loginManager.logIn(readPermissions: [.email, .publicProfile], viewController: self) { (result) in
            switch result {
            case .failed(let error):
                print("Error")
                self.stopSpinner()
                print(error)
            case .cancelled:
                self.stopSpinner()
                print("User cancelled login.")
            case .success(_, _, let accessToken):
                print("Logged in")
                self.startSpinner()
                let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.authenticationToken)
                Auth.auth().signInAndRetrieveData(with: credential) { (user, error) in
                    if let error = error {
                        self.stopSpinner()
                        print(error)
                        return
                    }
                    self.stopSpinner()
                    guard let currentUser = user else { return }
                    FirestoreManager.shared.checkIfUserExists(uid: currentUser.user.uid).then({ (exists) in
                        if exists {
                            FirestoreManager.shared.fetchUser(uid: currentUser.user.uid).then { (user) in
                                if user.isOnboarded {
                                    self.dismiss(animated: true, completion: nil)
                                } else {
                                    let userProfileFormViewController = UserProfileFormViewController()
                                    userProfileFormViewController.name = currentUser.user.displayName!
                                    userProfileFormViewController.email = currentUser.user.email!
                                    userProfileFormViewController.uid = currentUser.user.uid
                                    self.navigationItem.setHidesBackButton(true, animated: true)
                                    self.navigationController?.pushViewController(userProfileFormViewController, animated: true)
                                }
                            }
                        } else {
                            let userProfileFormViewController = UserProfileFormViewController()
                            userProfileFormViewController.name = currentUser.user.displayName!
                            userProfileFormViewController.email = currentUser.user.email!
                            userProfileFormViewController.uid = currentUser.user.uid
                            self.navigationItem.setHidesBackButton(true, animated: true)
                            self.navigationController?.pushViewController(userProfileFormViewController, animated: true)
                        }
                    })
                }
            }
        }
        self.stopSpinner()
    }
}
