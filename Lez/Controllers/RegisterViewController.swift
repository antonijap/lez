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

class RegisterViewController: UIViewController {
    
    let facebookLoginButton = UIButton()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLoginButter()
//        loginButton = FBSDKLoginButton()
//        loginButton.readPermissions = ["public_profile", "email"]
//        loginButton.delegate = self
//        view.addSubview(loginButton)
//        loginButton.snp.makeConstraints { (make) in
//            make.centerX.equalToSuperview()
//            make.centerY.equalToSuperview().inset(90)
//        }
    }
    
    func setupLoginButter() {
        // Add a custom login button to your app
        facebookLoginButton.backgroundColor = .blue
        facebookLoginButton.setTitle("Login with Facebook", for: .normal)
        
        // Handle clicks on the button
        facebookLoginButton.addTarget(self, action: #selector(self.facebookButtonTapped), for:.touchUpInside)
        
        // Add the button to the view
        view.addSubview(facebookLoginButton)
        facebookLoginButton.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(48)
            make.bottom.equalToSuperview().inset(100)
        }
    }
    
    @objc func facebookButtonTapped() {
        let loginManager = LoginManager()
        loginManager.logIn(readPermissions: [.email, .publicProfile], viewController: self) { (result) in
            switch result {
            case .failed(let error):
                print(error)
            case .cancelled:
                print("User cancelled login.")
            case .success(_, _, let accessToken):
                
                print("Logged in!")
                let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.authenticationToken)
                Auth.auth().signIn(with: credential) { (user, error) in
                    if let error = error {
                        print(error)
                        return
                    }
                    // User is signed in
                    guard let current = user else { return }

                    FirestoreManager.shared.fetchUser(uid: current.uid).then { (user) in
                        if user.isOnboarded {
                            self.dismiss(animated: true, completion: nil)
                        } else {
                            let setupProfileViewController = SetupProfileViewController()
                            setupProfileViewController.name = current.displayName!
                            setupProfileViewController.email = current.email!
                            setupProfileViewController.uid = current.uid
                            self.navigationController?.pushViewController(setupProfileViewController, animated: true)
                            self.navigationItem.setHidesBackButton(true, animated: true)
                        }
                    }
                }
            }
        }
    }
    
//    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
//        if let error = error {
//            print(error.localizedDescription)
//            return
//        }
//        // Start Animating
//        let hud = JGProgressHUD(style: .dark)
//        hud.textLabel.text = "Please wait"
//        hud.vibrancyEnabled = true
//        hud.show(in: view)
//
//        // Hide Button
//        loginButton.isHidden = true
//
//        let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
//        Auth.auth().signIn(with: credential) { (user, error) in
//            if let error = error {
//                print(error)
//                return
//            }
//            // User is signed in
//            print(user!)
//            guard let usr = user else { return }
//            let setupProfileViewController = SetupProfileViewController()
//            setupProfileViewController.name = usr.displayName!
//            setupProfileViewController.email = usr.email!
//            setupProfileViewController.uid = usr.uid
//            hud.dismiss(animated: true)
//            self.navigationController?.pushViewController(setupProfileViewController, animated: true)
//            self.navigationItem.setHidesBackButton(true, animated: true)
//        }
//    }
}
