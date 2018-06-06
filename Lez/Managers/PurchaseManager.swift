//
//  PurchaseManager.swift
//  Lez
//
//  Created by Antonija on 03/06/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Foundation
import SwiftyStoreKit
import SwiftDate
import Promises
import Firebase

final class PurchaseManager {
    
    static let shared = PurchaseManager()
    private let secret = "fdedb790950649388f3863bf6602ca66"
    
    func checkIfSubscribed(uid: String, ifManuallyPromoted: Bool) {
        if ifManuallyPromoted {
            
        } else {
            let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: self.secret)
            SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
                switch result {
                case .success(let receipt):
                    let productId = "premium"
                    let purchaseResult = SwiftyStoreKit.verifySubscription(
                        ofType: .autoRenewable,
                        productId: productId,
                        inReceipt: receipt)
                    switch purchaseResult {
                    case .purchased(let purchaseDate):
                        print("Purchased date \(purchaseDate)")
                    case .expired(let expiryDate):
                        print("Expiry date \(expiryDate)")
                        if expiryDate.expiryDate.isInPast {
                            self.deactivatePremiumInFirestore(uid: uid)
                        }
                    case .notPurchased:
                        print("Not purchased.")
                    }
                case .error(let error):
                    print("Receipt verification failed: \(error)")
                }
            }
        }
    }
    
    enum PurchaseOutcomes {
        case failed
        case success
    }
    
    func purchasePremium(completion: @escaping (_ error: PurchaseOutcomes) -> Void) {
        SwiftyStoreKit.purchaseProduct("premium", atomically: true) { result in
            guard let currentUser = Auth.auth().currentUser else { return }
            if case .success(let purchase) = result {
                if purchase.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }
                self.markUserAsPremium(uid: currentUser.uid, completion: { (error) in
                    if error {
                        completion(.failed)
                    } else {
                        completion(.success)
                    }
                })
            } else {
                print("Purchase error.")
                completion(.failed)
            }
        }
    }
    
    enum RestoreOutcomes {
        case failed
        case nothingToRestore
        case success
        case expired
    }
    
    func restore(completion: @escaping (_ error: RestoreOutcomes) -> Void) {
        guard let currentUser = Auth.auth().currentUser else { return }
        SwiftyStoreKit.restorePurchases(atomically: true) { results in
            if results.restoreFailedPurchases.count > 0 {
                completion(.failed)
            }
            else if results.restoredPurchases.count > 0 {
                // Check if restore is valid
                let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: self.secret)
                SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
                    switch result {
                    case .success(let receipt):
                        let productId = "premium"
                        let purchaseResult = SwiftyStoreKit.verifySubscription(
                            ofType: .autoRenewable,
                            productId: productId,
                            inReceipt: receipt)
                        switch purchaseResult {
                        case .purchased(let purchaseDate):
                            print("Purchased date \(purchaseDate)")
                            self.markUserAsPremium(uid: currentUser.uid, completion: { (error) in
                                if error {
                                    completion(.failed)
                                } else {
                                    completion(.success)
                                }
                            })
                        case .expired(let expiryDate):
                            print("Expiry date \(expiryDate)")
                            if expiryDate.expiryDate.isInPast {
                                completion(.expired)
                                self.deactivatePremiumInFirestore(uid: currentUser.uid)
                            }
                        case .notPurchased:
                            completion(.nothingToRestore)
                            print("Not purchased.")
                        }
                    case .error(let error):
                        print("Receipt verification failed: \(error)")
                        completion(.failed)
                    }
                }
            }
            else {
                completion(.nothingToRestore)
            }
        }
    }
    
    private func markUserAsPremium(uid: String, completion: @escaping (_ error: Bool) -> Void) {
        let data: [String: Any] = [
            "isPremium": true,
            "cooldownTime": "",
            "likesLeft": 5
        ]
        FirestoreManager.shared.updateUser(uid: uid, data: data).then { (success) in
            if success {
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    private func deactivatePremiumInFirestore(uid: String) {
        let data: [String: Any] = [
            "isPremium": false,
            "cooldownTime": "",
        ]
        FirestoreManager.shared.updateUser(uid: uid, data: data).then { (success) in
            if success {
                print("User demoted to free.")
            }
        }
    }

}

