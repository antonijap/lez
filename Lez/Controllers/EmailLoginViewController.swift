//
//  EmailLoginViewController.swift
//  Lez
//
//  Created by Antonija on 19/07/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import UIKit
import Firebase
import Alertift

enum FormStates {
    case empty
    case tooShort
    case success
    case notValidEmail
}

class EmailLoginViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - Properties
    
    private let emailTextField = CustomTextField()
    private let passwordTextField = CustomTextField()
    private let firstTitleLabel = UILabel()
    private let secondTitleLabel = UILabel()
    private let registerTitleLabel = UITextField()
    private let loginButton = PrimaryButton()
    private let createAccountButton = SecondaryButton()
    private let backgroundImageView = UIImageView()
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }
    
    
    // MARK: - Methods
    
    @objc private func loginButtonTapped() {
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        
        switch checkFormState(text: [email, password], isEmail: true) {
        case .empty:
            Alertift.alert(title: "", message: "Some fields are missing!")
                .action(.default("Okay"))
                .show(on: self, completion: nil)
        case .tooShort:
            Alertift.alert(title: "", message: "Wrong password. Try again.")
                .action(.default("Okay"))
                .show(on: self, completion: nil)
        case .notValidEmail:
            Alertift.alert(title: "", message: "It seems you haven't put a valid email.")
                .action(.default("Okay"))
                .show(on: self, completion: nil)
        default:
            Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                guard let error = error as NSError? else {
                    
                    // Check if a user is onboarded, if NOT then show form
                    guard let currentUser = user else { return }
                    
                    // Check if there is UID in Firestore
                    // Note: If there is no document at the location referenced by docRef, the resulting document will be empty and calling exists on it will return false.
                    let docRef = Firestore.firestore().collection("users").document(currentUser.user.uid)
                    docRef.getDocument(completion: { (snapshot, error) in
                        if error != nil {
                            print(error!.localizedDescription)
                        }
                        
                        guard let snapshot = snapshot else { return }

                        
                        if snapshot.exists {
                            print("Check onboarding.")
                            FirestoreManager.shared.fetchUser(uid: currentUser.user.uid).then { user in
                                guard user.isOnboarded else {
                                    let userProfileFormViewController = UserProfileFormViewController()
                                    guard let displayName = currentUser.user.displayName else { return }
                                    userProfileFormViewController.name = displayName
                                    if let email = currentUser.user.email { userProfileFormViewController.email = email }
                                    userProfileFormViewController.uid = currentUser.user.uid
                                    self.navigationItem.setHidesBackButton(true, animated: true)
                                    self.navigationController?.pushViewController(userProfileFormViewController, animated: true)
                                    return
                                }
                                // User is onboarded so let them to Match Room
                                self.dismiss(animated: true)
                            }
                        } else {
                            print("Toss directly to onboarding.")
                            let userProfileFormViewController = UserProfileFormViewController()
                            if let displayName = currentUser.user.displayName { userProfileFormViewController.name = displayName }
                            if let email = currentUser.user.email { userProfileFormViewController.email = email }
                            userProfileFormViewController.uid = currentUser.user.uid
                            userProfileFormViewController.isEmailDisabled = true
//                            self.navigationItem.setHidesBackButton(true, animated: true)
                            self.navigationController?.pushViewController(userProfileFormViewController, animated: true)
                        }
                    })
     
                    return
                }
                
                if error.code == 17011 {
                    Alertift.alert(title: "", message: "No user with that email.")
                        .action(.default("Okay"))
                        .show(on: self, completion: nil)
                }
                
                if error.code == 17009 {
                    Alertift.alert(title: "", message: "Password is wrong, try again.")
                        .action(.default("Okay"))
                        .action(.default("Reset Password"), handler: { (action, int, text) in
                            Auth.auth().sendPasswordReset(withEmail: email) { (error) in
                                guard let error = error as NSError? else { return }
                                print(error)
                            }
                        })
                        .show(on: self, completion: nil)
                }
                
                Alertift.alert(title: "Oopsie", message: error.localizedDescription)
                    .action(.default("Okay"))
                    .show(on: self, completion: nil)
                
                print(error)
            }
        }
    }
    
    @objc private func createAccountButtonTapped() {
        let createAccountViewController = CreateAccountViewController()
        self.navigationController?.pushViewController(createAccountViewController, animated: true)
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

extension EmailLoginViewController {
    
    // MARK: - Setup UI
    private func setupUI() {
        
        // Setup background color
        
        view.backgroundColor = .white
        
        view.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        backgroundImageView.image = #imageLiteral(resourceName: "Email_Login_Background")
        
        // Add first label
        
        view.addSubview(firstTitleLabel)
        firstTitleLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
            make.height.equalTo(44)
        }
        firstTitleLabel.text = "Existing Users"
        firstTitleLabel.textAlignment = .center
        firstTitleLabel.font = .systemFont(ofSize: 21, weight: .medium)
        
        
        // Add email textfield
        
        view.addSubview(emailTextField)
        emailTextField.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.top.equalTo(firstTitleLabel.snp.bottom).offset(16)
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
        passwordTextField.isSecureTextEntry = true
        
        
        // Add email login
        
        view.addSubview(loginButton)
        loginButton.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.top.equalTo(passwordTextField.snp.bottom).offset(8)
            make.height.equalTo(44)
        }
        loginButton.setTitle("Login", for: .normal)
        loginButton.addTarget(self, action: #selector(self.loginButtonTapped), for: .touchUpInside)
        
        
        // Add second label
        
        view.addSubview(secondTitleLabel)
        secondTitleLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.top.equalTo(loginButton.snp.bottom).offset(42)
            make.height.equalTo(44)
        }
        secondTitleLabel.text = "New Users"
        secondTitleLabel.textAlignment = .center
        secondTitleLabel.font = .systemFont(ofSize: 21, weight: .medium)
        
        
        // Add create account login
        
        view.addSubview(createAccountButton)
        createAccountButton.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.top.equalTo(secondTitleLabel.snp.bottom).offset(16)
            make.height.equalTo(44)
        }
        createAccountButton.setTitle("Create Account", for: .normal)
        createAccountButton.addTarget(self, action: #selector(self.createAccountButtonTapped), for: .touchUpInside)
    }
    
    private func setupNavigationBar() {
        navigationItem.title = ""
        navigationController?.navigationBar.backgroundColor = UIColor(red:0.97, green:0.97, blue:0.97, alpha:1.00)
        navigationController?.navigationBar.setBackgroundImage(#imageLiteral(resourceName: "Gray"), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layer.shadowRadius = 0
        navigationController?.navigationBar.tintColor = .black
    }
}


class CustomTextField: UITextField, UITextFieldDelegate {
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        delegate = self
        setupBackground()
        setupPadding()
    }
    required override init(frame: CGRect) {
        super.init(frame: frame)
        delegate = self
        setupBackground()
        setupPadding()
    }
    
    private func setupBackground() {
        layer.backgroundColor = UIColor.white.cgColor
        layer.cornerRadius = 4
        layer.borderWidth = 2
        layer.borderColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.00).cgColor
    }
    
    private func setupPadding() {
        layer.sublayerTransform = CATransform3DMakeTranslation(8, 0, 0);
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        print("Focused")
        guard let text = textField.text else { return }
        if text == "Email" || text == "Password" {
            self.text = nil
            self.textColor = .black
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        print("Lost focus")
        guard let text = textField.text else { return }
        if text == "Email" || text == "Password" {
            self.textColor = .lightGray
        } else if text.isEmpty {
            guard self.tag == 0 else { self.text = "Password"; self.textColor = .lightGray; return }
            self.text = "Email"
            self.textColor = .lightGray
        }
    }
}

extension String {
    func isValidEmail() -> Bool {
        // here, `try!` will always succeed because the pattern is valid
        let regex = try! NSRegularExpression(pattern: "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$", options: .caseInsensitive)
        return regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: count)) != nil
    }
}
