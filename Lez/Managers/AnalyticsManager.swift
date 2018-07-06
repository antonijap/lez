//
//  AnalyticsManager.swift
//  Lez
//
//  Created by Antonija Pek on 21/05/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Foundation
import Firebase

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
}