//
//  RegisterViewController.swift
//  Lez
//
//  Created by Antonija on 30/03/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase
import JGProgressHUD

class RegisterViewController: UIViewController, FBSDKLoginButtonDelegate {
    
    var loginButton: FBSDKLoginButton!
    
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

        loginButton = FBSDKLoginButton()
        loginButton.readPermissions = ["public_profile", "email"]
        loginButton.delegate = self
        view.addSubview(loginButton)
        loginButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().inset(90)
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        // Start Animating
        let hud = JGProgressHUD(style: .dark)
        hud.textLabel.text = "Please wait"
        hud.vibrancyEnabled = true
        hud.show(in: view)
        // Hide Button
        loginButton.isHidden = true
        
        let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
        Auth.auth().signIn(with: credential) { (user, error) in
            print("Facebook DONE")
            if let error = error {
                print(error)
                return
            }
            // User is signed in
            guard let usr = user else { return }
            let setupProfileViewController = SetupProfileViewController()
            setupProfileViewController.name = usr.displayName!
            setupProfileViewController.email = usr.email!
            setupProfileViewController.uid = usr.uid
            hud.dismiss(animated: true)
            self.navigationController?.pushViewController(setupProfileViewController, animated: true)
            self.navigationItem.setHidesBackButton(true, animated: true)
        }
    }
}
