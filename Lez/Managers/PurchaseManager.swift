//
//  PurchaseManager.swift
//  Lez
//
//  Created by Antonija on 03/06/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Foundation
import StoreKit
import SwiftyStoreKit
import SwiftDate
import Promises
import Firebase

// MARK: - Type Aliases

typealias ProductsIDs = Set<String>
typealias Completion = (Set<SKProduct>) -> Void
typealias CompletionMsg = (UIAlertController) -> Void
typealias PurchaseOutcomeCompletion = (PurchaseOutcomes) -> Void
typealias RestoreOutcomeCompletion = (RestoreOutcomes) -> Void
typealias ProductID = String

// MARK: - Error Handling

enum PurchaseOutcomes {
    case failed
    case success
}

enum RestoreOutcomes {
    case failed
    case nothingToRestore
    case success
    case expired
}

struct PurchaseManager {

    // MARK: - Properties

    /// The ID's for your products
    static private let productsIDs: ProductsIDs = ["premium"]

    // MARK: - Methods

    /// Fetches the products from the app store
    /// - Parameter completion: Fetched Products
    static func fetchProducts(completion: @escaping Completion) {
        SwiftyStoreKit.retrieveProductsInfo(productsIDs) { productsInfo in
            handleProducts(from: productsInfo, { products in completion(products) })
        }
    }

    /// We use this method to purchase Premium Subscription from
    /// the products that were fetched from the app store.
    /// - Parameters:
    ///   - productID: The product ID we want to purchase
    ///   - completion: The result if the product was succesfully purchased or if it failed
    static func purchase(_ productID: String, _ completion: @escaping (PurchaseOutcomes) -> Void) {
        SwiftyStoreKit.purchaseProduct(productID, atomically: true) { result in
            switch result {
            case .success:
                completion(.success); self.markUserAsPremium()
            case let .error(error):
                completion(.failed); self.deactivatePremiumInFirestore()
                handleError(error)
            }
        }
    }

    static func verifyPurchase(_ productID: ProductID) {
        verifyReceipt { (result) in
            switch result {
            case .success(let receipt): // This triggers password prompt
                print("Receipt is \(receipt)")
                verifySubscription(productID, with: receipt, isRestore: false)
            case .error(let error):
                print("There was an error \(error)")
            }
        }
    }

    static func restorePurchase(_ completion: @escaping RestoreOutcomeCompletion) {
        SwiftyStoreKit.restorePurchases(atomically: true) { result in
            if result.restoreFailedPurchases.count > 0 {
                completion(.failed)
            } else if result.restoredPurchases.count > 0 {
                if let product = result.restoredPurchases.last {
                    verifyPurchaseRestoreWith(product.productId) { outcome in completion(outcome) }
                }
            } else {
                completion(.nothingToRestore)
            }
        }
    }
    
    // MARK: - Helper Methods

    fileprivate static func verifyPurchaseRestoreWith(_ productID: String, completion: @escaping RestoreOutcomeCompletion) {
        verifyReceipt { result in
            switch result {
            case let .success(receipt):
                verifySubscription(productID, with: receipt, isRestore: true, completion: completion)
            case let .error(error):
                completion(.failed)
                print("There was an Error: \(error.localizedDescription) in PurchaseManager")
            }
        }
    }

    fileprivate static func verifyReceipt(completion: @escaping (VerifyReceiptResult) -> Void) {
        let sharedSecret = "fdedb790950649388f3863bf6602ca66"
        let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: sharedSecret)
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { completion($0) }
    }

    fileprivate static func verifySubscription(_ productID: ProductID, with receipt: ReceiptInfo, isRestore: Bool,
                                               completion: RestoreOutcomeCompletion? = nil) {
        let result = SwiftyStoreKit.verifySubscription(ofType: .autoRenewable,
                                                       productId: productID,
                                                       inReceipt: receipt,
                                                       validUntil: Date())
        handleSubscription(result, isRestore: isRestore, completion: completion)
    }

    /// Checks if the result has products and if their ID's are valid
    /// - Parameters:
    ///   - result: The products information result
    ///   - completion: Sends a Set of the received products if there are any
    fileprivate static func handleProducts(from result: RetrieveResults, _ completion: @escaping Completion ) {
        if let invalidProductsIDs = result.invalidProductIDs.first {
            print("Invalid Product ID's: \(invalidProductsIDs)")
        } else if !result.retrievedProducts.isEmpty {
            let products = result.retrievedProducts
            completion(products)
        } else {
            guard let error = result.error else { return }
            print("Error : \(error)")
        }
    }

    fileprivate static func handleSubscription(_ result: VerifySubscriptionResult, isRestore: Bool,
                                               completion: RestoreOutcomeCompletion?) {
        switch result {
        case .purchased:
            if isRestore { completion!(.success) }
            markUserAsPremium()
        case .expired:
            if isRestore { completion!(.expired) }
            deactivatePremiumInFirestore()
        case .notPurchased:
            if isRestore { completion!(.nothingToRestore) }
            deactivatePremiumInFirestore()
        }
    }

    fileprivate static func handleError(_ error: SKError){
        switch error.code {
        case .unknown: print("Unknown error. Please contact support")
        case .clientInvalid: print("Not allowed to make the payment")
        case .paymentCancelled: break
        case .paymentInvalid: print("The purchase identifier was invalid")
        case .paymentNotAllowed: print("The device is not allowed to make the payment")
        case .storeProductNotAvailable: print("The product is not available in the current storefront")
        case .cloudServicePermissionDenied: print("Access to cloud service information is not allowed")
        case .cloudServiceNetworkConnectionFailed: print("Could not connect to the network")
        case .cloudServiceRevoked: print("User has revoked permission to use this cloud service")
        }
    }
}

extension PurchaseManager {
    fileprivate static func markUserAsPremium() {
        guard let currentUser = Auth.auth().currentUser else { return }
        let data: [String: Any] = ["isPremium": true,
                                   "cooldownTime": "",
                                   "likesLeft": 5]
        // FIXME: - Check if user was updated in firebase
        FirestoreManager.shared.updateUser(uid: currentUser.uid, data: data).then { _ in
            NotificationCenter.default.post(name: Notification.Name("UpdateProfile"), object: nil)
        }
    }

    fileprivate static func deactivatePremiumInFirestore() {
        guard let currentUser = Auth.auth().currentUser else { return }
        FirestoreManager.shared.fetchUser(uid: currentUser.uid).then { user in
            // Determine if there should be a cooldown widget before deleting shit in Firestore.
            guard user.cooldownTime == nil else { return }
            let timeUntilNewLikesUnlock = user.cooldownTime!.add(components: 30.minutes)
            guard !timeUntilNewLikesUnlock.isInFuture else { return } // Clock should run don't delete anything
            let data: [String: Any] = ["isPremium": false,
                                       "cooldownTime": ""]
            FirestoreManager.shared.updateUser(uid: currentUser.uid, data: data).fulfill(true)
        }
    }
}
