//
//  GetPremiumController.swift
//  Lez
//
//  Created by Antonija on 04/05/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import Alertift
import Firebase
import SwiftyStoreKit

class GetPremiumViewController: UIViewController {
    
    let closeButton = UIButton()
    let titleLabel = UILabel()
    let descriptionLabel = UILabel()
    let backgroundImageView = UIImageView()
    let buyButton = CustomButton()
    var matchViewControllerDelegate: MatchViewControllerDelegate?
    var sharedSecret = "TIOYZpYpJ{#kQvMGlfCBg3Ij"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupInterface()
        
        SwiftyStoreKit.retrieveProductsInfo(["premium"]) { result in
            if let product = result.retrievedProducts.first {
                let priceString = product.localizedPrice!
                print("Product: \(product.localizedDescription), price: \(priceString)")
            }
            else if let invalidProductId = result.invalidProductIDs.first {
                print("Invalid product identifier: \(invalidProductId)")
            }
            else {
                print("Error: \(String(describing: result.error))")
            }
        }
    }
    
    fileprivate func setupInterface() {
        view.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        backgroundImageView.image = UIImage(named: "Premium Background")
        backgroundImageView.contentMode = .scaleAspectFill
        
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(view.frame.height / 2.6)
            make.left.right.equalToSuperview()
        }
        titleLabel.text = "Get Premium"
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .heavy)
        
        view.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(40)
            make.right.equalToSuperview().inset(40)
        }
        descriptionLabel.text = "Unlimited matches for only 2,99 € per month"
        descriptionLabel.font = UIFont.systemFont(ofSize: 21, weight: .medium)
        descriptionLabel.numberOfLines = 2
        descriptionLabel.textAlignment = .center
        
        view.addSubview(buyButton)
        buyButton.snp.makeConstraints { (make) in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(32)
            make.left.equalToSuperview().offset(40)
            make.right.equalToSuperview().inset(40)
            make.height.equalTo(48)
        }
        buyButton.setTitle("Get Premium", for: .normal)
        buyButton.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        let buttonTap = UITapGestureRecognizer(target: self, action: #selector(self.buyTapped(_:)))
        buyButton.addGestureRecognizer(buttonTap)
        
        setupCloseButton()
    }
    
    fileprivate func markUserAsPremium(uid: String) {
        let data: [String: Any] = [
            "isPremium": true,
            "cooldownTime": "",
            "likesLeft": 5
        ]
        FirestoreManager.shared.updateUser(uid: uid, data: data).then { (success) in
            if success {
                self.dismiss(animated: true, completion: {
                    self.matchViewControllerDelegate?.refreshTableView()
                })
            } else {
                // Error happened, please contact support@getlez.com
                self.showOkayModal(messageTitle: "Error", messageAlert: "Something happened and we couldn't update your profile, please contact us on support@getlez.com", messageBoxStyle: .alert, alertActionStyle: .default, completionHandler: {
                    print("Error happened")
                })
            }
        }
    }
    
    fileprivate func setupCloseButton() {
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { (make) in
            make.width.equalTo(32)
            make.height.equalTo(32)
            make.right.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(32)
        }
        let image = UIImage(named: "Close")
        closeButton.setImage(image, for: .normal)
        closeButton.addTarget(self, action: #selector(self.closeButtonTapped(_:)), for:.touchUpInside)
    }
    
    @objc func closeButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func buyTapped(_ sender: UIButton) {
        guard let currentUser = Auth.auth().currentUser else { return }
        let productId = "premium"
        SwiftyStoreKit.purchaseProduct(productId, atomically: true) { result in
            if case .success(let purchase) = result {
                if purchase.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }
                let appleValidator = AppleReceiptValidator(service: .sandbox, sharedSecret: self.sharedSecret)
                SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
                    print("APPLE VALIDATOR")
                    print(result)
                    if case .success(let receipt) = result {
                        let purchaseResult = SwiftyStoreKit.verifySubscription(
                            ofType: .autoRenewable,
                            productId: productId,
                            inReceipt: receipt)
                        
                        switch purchaseResult {
                        case .purchased(let expiryDate, let receiptItems):
                            print("Product is valid until \(expiryDate)")
                            FirestoreManager.shared.fetchUser(uid: currentUser.uid).then({ (user) in
                                AnalyticsManager.shared.logEvent(name: AnalyticsEvents.userPurchasedPremium, user: user)
                            })
                            self.markUserAsPremium(uid: currentUser.uid)
                        case .expired(let expiryDate, let receiptItems):
                            print("Product is expired since \(expiryDate)")
                        case .notPurchased:
                            print("This product has never been purchased")
                        }
                        
                    } else {
                        // receipt verification error
                    }
                }
            } else {
                // purchase error
            }
        }

//        SwiftyStoreKit.purchaseProduct("premium", quantity: 1, atomically: true) { result in
//            switch result {
//            case .success:
//                FirestoreManager.shared.fetchUser(uid: currentUser.uid).then({ (user) in
//                    AnalyticsManager.shared.logEvent(name: AnalyticsEvents.userPurchasedPremium, user: user)
//                })
//                self.markUserAsPremium(uid: currentUser.uid)
//            case .error(let error):
//                switch error.code {
//                case .unknown: print("Unknown error. Please contact support")
//                case .clientInvalid: print("Not allowed to make the payment")
//                case .paymentCancelled: break
//                case .paymentInvalid: print("The purchase identifier was invalid")
//                case .paymentNotAllowed: print("The device is not allowed to make the payment")
//                case .storeProductNotAvailable: print("The product is not available in the current storefront")
//                case .cloudServicePermissionDenied: print("Access to cloud service information is not allowed")
//                case .cloudServiceNetworkConnectionFailed: print("Could not connect to the network")
//                case .cloudServiceRevoked: print("User has revoked permission to use this cloud service")
//                }
//            }
//        }
    }
    
}
