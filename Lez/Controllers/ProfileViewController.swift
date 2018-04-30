//
//  ProfileViewController.swift
//  Lez
//
//  Created by Antonija on 31/03/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import UIKit
import Firebase
import SnapKit
import moa
import SkeletonView
import JGProgressHUD
import Alertift

class ProfileViewController: UIViewController, ImageGalleryDelegate, ProfileViewDelegate {

    // MARK: - Variables
    let tableView = UITableView()
    let sections: [MenuSections] = [.profileImages, .headerCell, .titleWithDescription, .titleWithDescription, .titleWithDescription, .premiumMenu, .simpleMenu, .simpleMenu, .simpleMenu]
    var user: User?
    let tabBar = UITabBar()
    let hud = JGProgressHUD(style: .dark)
    var shouldRefresh = false
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        print("viewDidAppear")
        print(shouldRefresh)
        if shouldRefresh {
            print("Refresh happened")
            startSpinner(title: "Loading Profile")
            guard let currentUser = Auth.auth().currentUser else { return }
            FirestoreManager.shared.fetchUser(uid: currentUser.uid).then { (user) in
                self.user = user
                }.then { _ in
                    self.tableView.reloadData()
                    self.stopSpinner()
            }
            shouldRefresh = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startSpinner(title: "Loading Profile")
        guard let currentUser = Auth.auth().currentUser else { return }
        FirestoreManager.shared.fetchUser(uid: currentUser.uid).then { (user) in
            self.user = user
            }.then { _ in
                self.setupTableView()
                self.stopSpinner()
        }
    }
    
    func refreshProfile() {
        startSpinner(title: "Loading Profile")
        guard let currentUser = Auth.auth().currentUser else { return }
        FirestoreManager.shared.fetchUser(uid: currentUser.uid).then { (user) in
            self.user = user
            }.then { _ in
                self.tableView.reloadData()
                self.stopSpinner()
        }
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.right.left.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
        }
        tableView.backgroundColor = .white
        tableView.separatorColor = .clear
        tableView.isUserInteractionEnabled = true
        let insets = UIEdgeInsets(top: -20, left: 0, bottom: 48, right: 0)
        tableView.contentInset = insets
        tableView.register(ProfileImagesCell.self, forCellReuseIdentifier: "ProfileImagesCell")
        tableView.register(TitleWithDescriptionCell.self, forCellReuseIdentifier: "TitleWithDescriptionCell")
        tableView.register(SimpleMenuCell.self, forCellReuseIdentifier: "SimpleMenuCell")
        tableView.register(IconMenuCell.self, forCellReuseIdentifier: "IconMenuCell")
        tableView.register(PremiumMenuCell.self, forCellReuseIdentifier: "PremiumMenuCell")
        tableView.register(HeaderCell.self, forCellReuseIdentifier: "HeaderCell")
    }
    
    func startSpinner(title: String) {
        // Start Animating
        hud.textLabel.text = title
        hud.vibrancyEnabled = true
        hud.interactionType = .blockAllTouches
        hud.show(in: view)
    }
    
    func stopSpinner() {
        // Start Animating
        hud.dismiss(animated: true)
    }
    
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        switch sections[indexPath.section] {
            case.headerCell:
                let headerCell = tableView.dequeueReusableCell(withIdentifier: HeaderCell.reuseID) as! HeaderCell
                guard let user = user else { return UITableViewCell() }
                headerCell.titleLabel.text = user.name + ", " + "\(user.age)"
                headerCell.bodyLabel.text = "\(user.location.city)"
                cell = headerCell
            
            case .titleWithDescription:
                let titleWithDescriptionCell = tableView.dequeueReusableCell(withIdentifier: TitleWithDescriptionCell.reuseID) as! TitleWithDescriptionCell
                if indexPath.section == 2 {
                    guard let user = user else { return UITableViewCell() }
                    titleWithDescriptionCell.titleLabel.text = "I am here for"
                    let string = user.preferences.lookingFor.joined(separator: ", ")
                    titleWithDescriptionCell.bodyLabel.text = string
                }
                if indexPath.section == 3 {
                    guard let user = user else { return UITableViewCell() }
                    titleWithDescriptionCell.titleLabel.text = "About"
                    titleWithDescriptionCell.bodyLabel.text = user.details.about
                }
                if indexPath.section == 4 {
                    guard let user = user else { return UITableViewCell() }
                    titleWithDescriptionCell.titleLabel.text = "Dealbreakers"
                    titleWithDescriptionCell.bodyLabel.text = user.details.dealBreakers
                }
                cell = titleWithDescriptionCell
            
            case .profileImages:
                print("Messing with profile image")
                guard let user = user else { return UITableViewCell() }
                let profileImagesCell = tableView.dequeueReusableCell(withIdentifier: ProfileImagesCell.reuseID) as! ProfileImagesCell
                let url = user.images
                profileImagesCell.scrollView.auk.removeAll()
                for u in url! {
                    profileImagesCell.scrollView.auk.show(url: u)
                }
                cell = profileImagesCell
            
            case .iconMenu:
                let iconMenuCell = tableView.dequeueReusableCell(withIdentifier: IconMenuCell.reuseID) as! IconMenuCell
                cell = iconMenuCell
            
            case .simpleMenu:
                let simpleMenuCell = tableView.dequeueReusableCell(withIdentifier: SimpleMenuCell.reuseID) as! SimpleMenuCell
                if indexPath.section == 6 {
                    simpleMenuCell.titleLabel.text = "Edit Profile"
                    simpleMenuCell.titleLabel.textColor = .black
                }
                if indexPath.section == 7 {
                    simpleMenuCell.titleLabel.text = "Edit Images"
                }
                if indexPath.section == 8 {
                    simpleMenuCell.titleLabel.text = "Sign out"
                    simpleMenuCell.titleLabel.textColor = .red
                }
                cell = simpleMenuCell
            
            case .premiumMenu:
                let premiumMenuCell = tableView.dequeueReusableCell(withIdentifier: PremiumMenuCell.reuseID) as! PremiumMenuCell
                cell = premiumMenuCell
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath == [5, 0] {
            Alertift.alert(title: "Get Premium", message: "Building...")
                .action(.default("Okay"))
                .show()
        }
        if indexPath == [6, 0] {
            let setupProfileViewController = SetupProfileViewController()
            guard let user = user else { return }
            setupProfileViewController.currentUser = user
            setupProfileViewController.delegate = self
            setupProfileViewController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(setupProfileViewController, animated: true)
        }
        if indexPath == [7, 0] {
            let imageGalleryViewController = ImageGalleryViewController()
            guard let user = user else { return }
            imageGalleryViewController.user = user
            imageGalleryViewController.delegate = self
            imageGalleryViewController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(imageGalleryViewController, animated: true)
        }
        if indexPath == [8, 0] {
            self.showSignoutAlert(CTA: "Sign out")  
        }
    }
}


