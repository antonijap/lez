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

class ProfileViewController: UIViewController {
    
    // MARK: - Variables
    let tableView = UITableView()
    let sections: [Sections] = [.profileImages, .titleWithDescription, .titleWithDescription, .titleWithDescription, .titleWithDescription, .premiumMenu, .simpleMenu, .simpleMenu, .simpleMenu]
    var user: User?
    let closeButton = UIButton()
    let tabBar = UITabBar()
    let hud = JGProgressHUD(style: .dark)
    // Old
    var profileImageView: UIImageView!
    var label: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        // Fetch current user
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        view.showAnimatedSkeleton()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startSpinner(title: "Loading Profile")
        guard let uid = DefaultsManager.shared.fetchUID() else { return }
        FirestoreManager.shared.fetchCurrentUser(uid: uid).then { (user) in
            self.user = user
            }.then { _ in
                self.setupTableView()
                self.setupCloseButton()
                self.stopSpinner()
        }
    }
    
    @objc func logoutTapped(_ sender: UIButton) {
        let firebaseAuth = Auth.auth()
        do { 
            // Add Facebook logout
            try firebaseAuth.signOut()
            print("Signed out")
            let registerViewController = RegisterViewController()
            let navigationController = UINavigationController(rootViewController: registerViewController)
            self.present(navigationController, animated: false, completion: nil)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    @objc func closeButtonTapped(_ sender:UIButton) {
        dismiss(animated: true, completion: nil)
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
    }
    
    func setupCloseButton() {
        view.insertSubview(closeButton, aboveSubview: tableView)
        closeButton.snp.makeConstraints { (make) in
            make.width.equalTo(32)
            make.height.equalTo(32)
            make.right.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(32)
        }
        let image = UIImage(named: "Close")
        closeButton.setImage(image, for: .normal)
        closeButton.addTarget(self, action: #selector(self.closeButtonTapped(_:)), for:.touchUpInside)
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
            case .titleWithDescription:
            let titleWithDescriptionCell = tableView.dequeueReusableCell(withIdentifier: TitleWithDescriptionCell.reuseID) as! TitleWithDescriptionCell
            if indexPath.section == 1 {
                guard let user = user else { return UITableViewCell() }
                titleWithDescriptionCell.titleLabel.textColor = .black
                titleWithDescriptionCell.titleLabel.font = UIFont.systemFont(ofSize: 21.0)
                titleWithDescriptionCell.titleLabel.text = user.name + ", " + "\(user.age)"
                titleWithDescriptionCell.bodyLabel.text = "\(user.location.city)"
                titleWithDescriptionCell.bodyLabel.snp.remakeConstraints({ (make) in
                    make.left.right.equalToSuperview().inset(32)
                    make.top.equalTo(titleWithDescriptionCell.titleLabel.snp.bottom)
                    make.bottom.equalToSuperview().offset(-16)
                })
            }
            if indexPath.section == 2 {
                titleWithDescriptionCell.titleLabel.text = "I am here for"
                titleWithDescriptionCell.bodyLabel.text = "Relationship, Friendship"
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
            guard let user = user else { return UITableViewCell() }
            let profileImagesCell = tableView.dequeueReusableCell(withIdentifier: ProfileImagesCell.reuseID) as! ProfileImagesCell
            let url = user.images
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
        print(indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath)
        if indexPath == [6, 0] {
        }
        if indexPath == [7, 0] {
            
        }
        if indexPath == [8, 0] {
            
        }
    }
}


