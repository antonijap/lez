//
//  DispatchManager.swift
//  Lez
//
//  Created by Antonija on 01/04/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Foundation

class DispatchGroupManager {
    static let sharedInstance = DispatchGroupManager()
    
    let dispatchGroup = DispatchGroup()
    private init() { }
}
