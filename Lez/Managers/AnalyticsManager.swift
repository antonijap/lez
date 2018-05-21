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
    case test = "test_happened"
    case purchaseHappened = "purchase_happened"
}

final class AnalyticsManager {
    
    private init() { }
    static let shared = AnalyticsManager()
    
    func logEvent(name: AnalyticsEvents, user: User) {
        Analytics.logEvent(name.rawValue, parameters: [
            "name": user.name,
            "email": user.email,
            "age": user.age
        ])
    }
}
