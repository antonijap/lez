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
    
    let facebookLoginButton = UIButton()
    let hud = JGProgressHUD(style: .dark)
    
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
        setupButtons()
        
        if let currentUser = Auth.auth().currentUser {
            let setupProfileViewController = UserProfileFormViewController()
            setupProfileViewController.name = currentUser.displayName!
            setupProfileViewController.email = currentUser.email!
            setupProfileViewController.uid = currentUser.uid
            navigationItem.hidesBackButton = true
            navigationController?.pushViewController(setupProfileViewController, animated: true)
        }
    }
    
    fileprivate func startSpinner() {
        hud.textLabel.text = "Logging in"
        hud.show(in: view)
        hud.interactionType = .blockAllTouches
        hud.detailTextLabel.font = UIFont.systemFont(ofSize: 9.0, weight: .regular)
    }
    
    fileprivate func stopSpinner() {
        hud.dismiss(animated: true)
    }

    fileprivate func setupButtons() {
        let twitterLoginButton = TWTRLogInButton(logInCompletion: { session, error in
            if let session = session {
                self.startSpinner()
                let credential = TwitterAuthProvider.credential(withToken: session.authToken, secret: session.authTokenSecret)
                Auth.auth().signInAndRetrieveData(with: credential) { (user, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    // User is signed in
                    guard let current = user else { return }
                    FirestoreManager.shared.checkIfUserExists(uid: current.user.uid).then({ (exists) in
                        if exists {
                            FirestoreManager.shared.fetchUser(uid: current.user.uid).then { (user) in
                                if user.isOnboarded {
                                    self.stopSpinner()
                                    self.dismiss(animated: true, completion: nil)
                                } else {
                                    let setupProfileViewController = UserProfileFormViewController()
                                    setupProfileViewController.uid = current.user.uid
                                    self.navigationItem.setHidesBackButton(true, animated: true)
                                    self.navigationController?.pushViewController(setupProfileViewController, animated: true)
                                }
                            }
                        } else {
                            let setupProfileViewController = UserProfileFormViewController()
                            setupProfileViewController.uid = current.user.uid
                            self.navigationItem.setHidesBackButton(true, animated: true)
                            self.navigationController?.pushViewController(setupProfileViewController, animated: true)
                        }
                    })
                }
            }
        })
        
        view.addSubview(twitterLoginButton)
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
   
    @objc func facebookButtonTapped() {
        let loginManager = LoginManager()
        loginManager.logOut()
        loginManager.logIn(readPermissions: [.email, .publicProfile], viewController: self) { (result) in
            switch result {
            case .failed(let error):
                print("Error")
                print(error)
            case .cancelled:
                print("User cancelled login.")
            case .success(_, _, let accessToken):
                print("Logged in")
                self.startSpinner()
                let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.authenticationToken)
                Auth.auth().signInAndRetrieveData(with: credential) { (user, error) in
                    if let error = error {
                        print(error)
                        return
                    }
                    guard let currentUser = user else { return }
                    FirestoreManager.shared.checkIfUserExists(uid: currentUser.user.uid).then({ (exists) in
                        if exists {
                            FirestoreManager.shared.fetchUser(uid: currentUser.user.uid).then { (user) in
                                if user.isOnboarded {
                                    self.stopSpinner()
                                    self.dismiss(animated: true, completion: nil)
                                } else {
                                    let setupProfileViewController = UserProfileFormViewController()
                                    setupProfileViewController.name = currentUser.user.displayName!
                                    setupProfileViewController.email = currentUser.user.email!
                                    setupProfileViewController.uid = currentUser.user.uid
                                    self.navigationItem.setHidesBackButton(true, animated: true)
                                    self.navigationController?.pushViewController(setupProfileViewController, animated: true)
                                }
                            }
                        } else {
                            let setupProfileViewController = UserProfileFormViewController()
                            setupProfileViewController.name = currentUser.user.displayName!
                            setupProfileViewController.email = currentUser.user.email!
                            setupProfileViewController.uid = currentUser.user.uid
                            self.navigationItem.setHidesBackButton(true, animated: true)
                            self.navigationController?.pushViewController(setupProfileViewController, animated: true)
                        }
                    })
                }
            }
        }
        self.stopSpinner()
    }
}
