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

final class PurchaseManager {
    
    static let shared = PurchaseManager()
    private let secret = "fdedb790950649388f3863bf6602ca66"
    
    func checkIfSubscribed(uid: String) {
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
                        deactivatePremiumInFirestore(uid: uid)
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

func deactivatePremiumInFirestore(uid: String) {
    let data: [String: Any] = [
        "isPremium": false,
        "cooldownTime": "",
        "likesLeft": 5
    ]
    FirestoreManager.shared.updateUser(uid: uid, data: data).then { (success) in
        if success {
            print("User demoted to free.")
        }
    }
}
