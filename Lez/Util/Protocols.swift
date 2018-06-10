//
//  Protocols.swift
//  Lez
//
//  Created by Antonija on 06/05/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Foundation

protocol MatchViewControllerDelegate {
    func refreshTableView()
    func fetchUsers(for uid: String)
    func runLikesWidget(uid: String)
}

protocol ProfileViewControllerDelegate {
    func refreshProfile()
}
