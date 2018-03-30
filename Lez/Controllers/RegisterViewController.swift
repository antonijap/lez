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

class RegisterViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let loginButton = FBSDKLoginButton()
        loginButton.readPermissions = ["public_profile", "email"]
        view.addSubview(loginButton)
        loginButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().inset(48)
        }
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        // Make Firebase user
        let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
        Auth.auth().signIn(with: credential) { (user, error) in
            if let error = error {
                print(error)
                return
            }
            // User is signed in
            // Write new user in Storage! -- NEW
        }
    }
}
