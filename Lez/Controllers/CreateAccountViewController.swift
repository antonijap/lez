//
//  CreateAccountViewControllerViewController.swift
//  Lez
//
//  Created by Antonija on 20/07/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import UIKit
import Firebase
import Alertift

class CreateAccountViewController: UIViewController {
    
    // Mark: - Properties
    private let emailTextField = CustomTextField()
    private let passwordTextField = CustomTextField()
    private let passwordConfirmTextField = CustomTextField()
    private let createAccountButton = PrimaryButton()
    private let backgroundImageView = UIImageView()
    
    var isInOptOut = false
    var oldProviderID: String?
    
    // Mark: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }
    
    
    // Mark: - Methods
    @objc private func createAccountButtonTapped() {
        
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        
        switch checkFormState(text: [email, password], isEmail: true) {
        case .empty:
            Alertift.alert(title: "", message: "Some fields are missing!")
                .action(.default("Okay"))
                .show(on: self, completion: nil)
        case .tooShort:
            Alertift.alert(title: "", message: "Password too short. More than 5 characters.")
                .action(.default("Okay"))
                .show(on: self, completion: nil)
        case .notValidEmail:
            Alertift.alert(title: "", message: "It seems you haven't put a valid email.")
                .action(.default("Okay"))
                .show(on: self, completion: nil)
        default:
            if self.isInOptOut {
                guard let currentUser = Auth.auth().currentUser else { print("No user"); return }

                // Link with email provider
                
                let credential = EmailAuthProvider.credential(withEmail: email, password: password)
                currentUser.linkAndRetrieveData(with: credential, completion: { (authResult, error) in
                    if let error = error {
                        Alertift.alert(title: "", message: error.localizedDescription)
                            .action(.default("Okay"))
                            .show(on: self, completion: nil)
                    }
                    
                    // Unlink from Social provider
                    
                    if currentUser.providerData.count > 0 {
                        for provider in currentUser.providerData {
                            print(provider.providerID)
                            if provider.providerID == "twitter.com" || provider.providerID == "facebook.com" {
                                currentUser.unlink(fromProvider: provider.providerID) { (user, error) in
                                    Alertift.alert(title: "", message: "Success. From now on, use only email login.")
                                        .action(.default("I understand"), handler: { _, _, _ in
                                            self.navigationController?.popViewController(animated: true)
                                        })
                                        .show(on: self, completion: {
                                            FirestoreManager.shared.fetchUser(uid: currentUser.uid).then({ user in
                                                AnalyticsManager.shared.logEvent(name: .userOptedOutFromSocialLogin, user: user)
                                            })
                                        })
                                }
                            }
                        }
                    }
                })
            } else {
                Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
                    guard let user = user else {
                        if let error = error {
                            Alertift.alert(title: "", message: error.localizedDescription)
                                .action(.default("Okay"))
                                .show(on: self, completion: nil)
                        }
                        return
                    }
                    // Regular flow, go through form
                    guard let currentUser = Auth.auth().currentUser else { print("No user"); return }
                    DefaultsManager.shared.saveCurrentUser(value: currentUser.uid)
                    FirestoreManager.shared.fetchUser(uid: currentUser.uid).then({ user in
                        AnalyticsManager.shared.logEvent(name: .userUsedEmailLogin, user: user)
                    })
                    
                    let userProfileFormViewController = UserProfileFormViewController()
                    userProfileFormViewController.email = user.user.email
                    userProfileFormViewController.isEmailDisabled = true
                    self.navigationController?.pushViewController(userProfileFormViewController, animated: true)
                }
            }
        }
    }
    
    private func checkFormState(text: [String], isEmail: Bool) -> FormStates {
        
        guard text[0] != "Email", text[1] != "Password", !text[0].isEmpty, !text[1].isEmpty else {
            return .empty
        }
        
        if isEmail {
            if !text[0].isValidEmail() {
                return .notValidEmail
            }
        }
        
        if text[1].count <= 5{
            return .tooShort
        }
        
        return .success
    }
}

extension CreateAccountViewController {
    
    // MARK: - Setup UI
    private func setupUI() {
        
        // Setup background color
        
        view.backgroundColor = .white
        
        view.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        backgroundImageView.image = #imageLiteral(resourceName: "Email_Login_Background")
        
        // Add email textfield
        
        view.addSubview(emailTextField)
        emailTextField.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin).offset(24)
            make.height.equalTo(44)
        }
        emailTextField.text = "Email"
        emailTextField.textColor = .lightGray
        emailTextField.tag = 0
        
        
        // Add password textfield
        
        view.addSubview(passwordTextField)
        passwordTextField.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.top.equalTo(emailTextField.snp.bottom).offset(8)
            make.height.equalTo(44)
        }
        passwordTextField.text = "Password"
        passwordTextField.textColor = .lightGray
        passwordTextField.tag = 1
//        passwordTextField.isSecureTextEntry = true
        
        // Add create account
        
        view.addSubview(createAccountButton)
        createAccountButton.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.top.equalTo(passwordTextField.snp.bottom).offset(8)
            make.height.equalTo(44)
        }
        createAccountButton.setTitle("Create Account", for: .normal)
        createAccountButton.addTarget(self, action: #selector(self.createAccountButtonTapped), for: .touchUpInside)

    }
    
    private func setupNavigationBar() {
        navigationItem.title = "Create Account"
        navigationController?.navigationBar.backgroundColor = UIColor(red:0.97, green:0.97, blue:0.97, alpha:1.00)
        navigationController?.navigationBar.setBackgroundImage(#imageLiteral(resourceName: "Gray"), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layer.shadowRadius = 0
    }
    
}
