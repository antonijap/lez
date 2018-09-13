//
//  AnalyticsManager.swift
//  Lez
//
//  Created by Antonija Pek on 21/05/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Foundation
import Firebase
import FacebookCore

enum AnalyticsEvents: String {
    case userRegistered = "user_registered"
    case userViewedProfile = "user_viewed_profile"
    case userBlockedSomebody = "user_blocked_somebody"
    case userReportedSomebody = "user_reported_somebody"
    case userPurchasedPremium = "user_purchased_premium"
    case userChurnded = "user_churned"
    case userEditedProfile = "user_edited_profile"
    case userDeletedAccount = "user_deleted_account"
    case matchHappened = "match_happened"
    case userAdjustedFilters = "user_adjusted_filters"
    case userSharedURL = "user_shared_URL"
    case userRunOutOfLikes = "user_run_out_of_likes"
    case userCounterReset = "user_counter_reset"
    case userUsedEmailLogin = "user_used_email_login"
    case userSubscriptionEnded = "user_subscription_ended"
    case userOptedOutFromSocialLogin = "user_opted_out_from_social_login"
    case userChangedLocationPreference = "user_changed_location_preference"
    case userCanceledPurchase = "user_canceled_purchase"
}

final class AnalyticsManager {
    
    private init() { }
    static let shared = AnalyticsManager()
    
    func logEvent(name: AnalyticsEvents, user: User) {
        // Check if user has opt-out from tracking
        guard DefaultsManager.shared.userWantsTracking() else { return }
        guard user.email != "hello@antonijapek.com" else {
            Analytics.logEvent(name.rawValue, parameters: ["name": user.name,
                                                           "email": user.email,
                                                           "age": user.age])
            return
        }
        guard name == .userPurchasedPremium else { return }
        Analytics.logEvent(name.rawValue, parameters: ["name": user.name,
                                                       "email": user.email,
                                                       "age": user.age,
                                                       AnalyticsParameterValue: 2.99])
    }

    func logDeleteEvent(name: AnalyticsEvents) {
        Analytics.logEvent(name.rawValue, parameters: nil)
    }
    
    
    func facebookLogPurchase(uid: String, email: String, price: Double, valueToSum: Double) {
        let params : AppEvent.ParametersDictionary = [
            "uid" : uid,
            "email" : email,
            "price": 2.99
        ]
        let event = AppEvent(name: AnalyticsEvents.userPurchasedPremium.rawValue, parameters: params, valueToSum: valueToSum)
        AppEventsLogger.log(event)
    }

    func facebookLogUserInMatchRoom(uid : String, email : String) {
        let params : AppEvent.ParametersDictionary = [
            "uid" : uid,
            "email" : email
        ]
        let event = AppEvent(name: "user_in_match_room", parameters: params)
        AppEventsLogger.log(event)
    }
}

