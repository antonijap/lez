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
import Crashlytics

class RegisterViewController: UIViewController {
    
    // MARK: - Properties
    
    private let facebookLoginButton = UIButton()
    private let twitterLoginButton = UIButton()
    private let hud = JGProgressHUD(style: .dark)
    private let backgroundImageView = UIImageView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let bureaucracyCrapButtonsView = UIView()
    private let privacyPolicyButton = UIButton()
    private let termsOfServiceButton = UIButton()
    private let subscriptionText = UILabel()
    
    // MARK: - View Lifecycle
    
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
        setupBureaucracyCrapButtons()
        if let currentUser = Auth.auth().currentUser {
            let setupProfileViewController = UserProfileFormViewController()
            guard let name = currentUser.displayName else { return }
            guard let email = currentUser.email else { return }
            setupProfileViewController.name = name
            setupProfileViewController.email = email
            setupProfileViewController.uid = currentUser.uid
            navigationItem.hidesBackButton = true
            navigationController?.pushViewController(setupProfileViewController, animated: true)
        }
    }
    
    // MARK: - Methods
    
    @objc private func privacyPolicyButtontapped() {
        if let url = URL(string: "https://www.iubenda.com/privacy-policy/89963959") {
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    @objc private func termsOfServiceButtontapped() {
        if let url = URL(string: "https://www.iubenda.com/privacy-policy/89963959") {
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    
    private func setupBackground() {
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(scrollView)
            make.left.right.equalTo(view)
        }
        
        contentView.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(view.frame.height)
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
                    self.startSpinner()
                    guard let currentUser = user else { return }
                    FirestoreManager.shared.checkIfUserExists(uid: currentUser.user.uid).then({ (exists) in
                        if exists {
                            FirestoreManager.shared.fetchUser(uid: currentUser.user.uid).then { (user) in
                                if user.isOnboarded {
                                    self.stopSpinner()
                                    self.dismiss(animated: true, completion: nil)
                                } else {
                                    self.stopSpinner()
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
                            self.stopSpinner()
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

extension RegisterViewController {
    private func setupBureaucracyCrapButtons() {
        contentView.addSubview(bureaucracyCrapButtonsView)
        if Device.IS_4_7_INCHES_OR_LARGER() {
            bureaucracyCrapButtonsView.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.width.equalToSuperview().dividedBy(2)
                make.top.equalTo(twitterLoginButton.snp.bottom).offset(40)
            }
        } else {
            bureaucracyCrapButtonsView.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.width.equalToSuperview().dividedBy(1.7)
                make.top.equalTo(twitterLoginButton.snp.bottom).offset(40)
            }
        }
        
        bureaucracyCrapButtonsView.addSubview(privacyPolicyButton)
        privacyPolicyButton.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
        }
        privacyPolicyButton.setTitle("Privacy Policy", for: .normal)
        privacyPolicyButton.setTitleColor(.gray, for: .normal)
        privacyPolicyButton.addTarget(self, action: #selector(self.privacyPolicyButtontapped), for: .touchUpInside)
        privacyPolicyButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        
        bureaucracyCrapButtonsView.addSubview(termsOfServiceButton)
        termsOfServiceButton.snp.makeConstraints { (make) in
            make.right.top.bottom.equalToSuperview()
        }
        termsOfServiceButton.setTitle("Terms of Service", for: .normal)
        termsOfServiceButton.setTitleColor(.gray, for: .normal)
        termsOfServiceButton.addTarget(self, action: #selector(self.termsOfServiceButtontapped), for: .touchUpInside)
        termsOfServiceButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        
        contentView.addSubview(subscriptionText)
        subscriptionText.snp.makeConstraints { (make) in
            make.top.equalTo(bureaucracyCrapButtonsView.snp.bottom).offset(40)
            make.bottom.equalToSuperview().inset(32)
            make.left.equalToSuperview().inset(32)
            make.right.equalToSuperview().inset(32)
        }
        subscriptionText.text = "Premium is monthly auto-renewable subscription of Lez and it offers subscription with price 2.99€ per month. Payment will be charged to iTunes Account at confirmation of purchase. Subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period. Account will be charged for renewal within 24-hours prior to the end of the current period. Subscriptions may be managed by the user and auto-renewal may be turned off by going to the iPhone’s settings."
        subscriptionText.numberOfLines = 20
        subscriptionText.font = UIFont.systemFont(ofSize: 9, weight: .regular)
        subscriptionText.textColor = .gray
    }
    
    private func setupButtons() {
        facebookLoginButton.setTitle("Login with Facebook", for: .normal)
        facebookLoginButton.addTarget(self, action: #selector(self.facebookButtonTapped), for:.touchUpInside)
        scrollView.addSubview(facebookLoginButton)
        facebookLoginButton.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(view.frame.height / 1.5)
            make.height.equalTo(48)
            make.width.equalToSuperview().dividedBy(1.2)
            make.centerX.equalToSuperview()
        }
        facebookLoginButton.backgroundColor = UIColor(red:0.28, green:0.37, blue:0.60, alpha:1.00)
        facebookLoginButton.layer.cornerRadius = 48 / 2
        
        scrollView.addSubview(twitterLoginButton)
        twitterLoginButton.setTitle("Login with Twitter", for: .normal)
        twitterLoginButton.addTarget(self, action: #selector(self.twitterButtonTapped), for:.touchUpInside)
        twitterLoginButton.snp.makeConstraints { (make) in
            make.top.equalTo(facebookLoginButton.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.height.equalTo(48)
            make.width.equalToSuperview().dividedBy(1.2)
        }
        twitterLoginButton.backgroundColor = UIColor(red:0.30, green:0.62, blue:0.93, alpha:1.00)
        twitterLoginButton.layer.cornerRadius = 48 / 2
    }
}
