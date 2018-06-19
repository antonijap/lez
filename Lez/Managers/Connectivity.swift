//
//  Connectivity.swift
//  Lez
//
//  Created by Antonija on 17/06/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Foundation
import Alamofire

class Connectivity {
    class var isConnectedToInternet:Bool {
        return NetworkReachabilityManager()!.isReachable
    }
}
