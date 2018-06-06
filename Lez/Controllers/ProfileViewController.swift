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
import JGProgressHUD
import Alertift
import Jelly
import ImageSlideshow
import SDWebImage
import SwiftyStoreKit
import Toast_Swift

class ProfileViewController: UIViewController, ProfileViewControllerDelegate {    

    // MARK: - Variables
    let tableView = UITableView()
    let sections: [MenuSections] = [.profileImages, .headerCell, .titleWithDescription, .titleWithDescription, .titleWithDescription, .titleWithDescription, .simpleMenu, .simpleMenu, .simpleMenu, .simpleMenu, .simpleMenu]
    var user: User?
    let tabBar = UITabBar()
    let hud = JGProgressHUD(style: .dark)
    var shouldRefresh = false
    var jellyAnimator: JellyAnimator?
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        if shouldRefresh {
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
    
    private func startSpinner(title: String) {
        // Start Animating
        hud.textLabel.text = title
        hud.vibrancyEnabled = true
        hud.interactionType = .blockAllTouches
        hud.show(in: view)
    }
    
    private func stopSpinner() {
        // Start Animating
        hud.dismiss(animated: true)
    }
    
//    private func markUserAsPremium(uid: String) {
//        let data: [String: Any] = [
//            "isPremium": true,
//            "cooldownTime": "",
//            "likesLeft": 5
//        ]
//        FirestoreManager.shared.updateUser(uid: uid, data: data).then { (success) in
//            if success {
//                FirestoreManager.shared.fetchUser(uid: uid).then({ (user) in
//                    self.user = user
//                    self.tableView.reloadData()
//                    self.view.makeToast("Premium activated", duration: 2.0, position: .bottom)
//                })
//            } else {
//                // Error happened, please contact support@getlez.com
//                self.showOkayModal(messageTitle: "Error", messageAlert: "Something happened and we couldn't update your profile, please contact us on support@getlez.com", messageBoxStyle: .alert, alertActionStyle: .default, completionHandler: {
//                    print("Error happened")
//                })
//            }
//        }
//    }
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
                if indexPath.section == 5 {
                    guard let user = user else { return UITableViewCell() }
                    titleWithDescriptionCell.titleLabel.text = "Diet"
                    titleWithDescriptionCell.bodyLabel.text = user.details.diet.rawValue
                }
                cell = titleWithDescriptionCell
            
            case .profileImages:
                guard let user = user else { return UITableViewCell() }
                let profileImagesCell = tableView.dequeueReusableCell(withIdentifier: ProfileImagesCell.reuseID) as! ProfileImagesCell
                profileImagesCell.slideshow.setImageInputs([])
                var sources: [SDWebImageSource] = []
                for image in user.images {
                    let sdWebImageSource = SDWebImageSource(urlString: image.url)
                    if let image = sdWebImageSource {
                        sources.append(image)
                    }
                }
                
                profileImagesCell.slideshow.setImageInputs(sources)
                cell = profileImagesCell
        
            case .iconMenu:
                let iconMenuCell = tableView.dequeueReusableCell(withIdentifier: IconMenuCell.reuseID) as! IconMenuCell
                cell = iconMenuCell
            
            case .simpleMenu:
                guard let user = user else { return UITableViewCell() }
                let simpleMenuCell = tableView.dequeueReusableCell(withIdentifier: SimpleMenuCell.reuseID) as! SimpleMenuCell
                if indexPath.section == 6 {
                    if user.isPremium {
                        simpleMenuCell.titleLabel.text = "You are Premium"
                    } else {
                        simpleMenuCell.titleLabel.text = "Unlock unlimited likes"
                    }
                    simpleMenuCell.titleLabel.textColor = .black
                    simpleMenuCell.titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
                }
                if indexPath.section == 7 {
                    simpleMenuCell.titleLabel.text = "Edit Profile"
                    simpleMenuCell.titleLabel.textColor = .black
                    simpleMenuCell.isUserInteractionEnabled = true
                }
                if indexPath.section == 8 {
                    simpleMenuCell.titleLabel.text = "Edit Images"
                    simpleMenuCell.isUserInteractionEnabled = true
                }
                if indexPath.section == 9 {
                    if user.isPremium {
                        simpleMenuCell.titleLabel.text = "Restore Subscription"
                        simpleMenuCell.titleLabel.textColor = .gray
                        simpleMenuCell.isUserInteractionEnabled = false
                    } else {
                        simpleMenuCell.titleLabel.text = "Restore Subscription"
                        simpleMenuCell.titleLabel.textColor = .black
                        simpleMenuCell.isUserInteractionEnabled = true
                    }
                    
                }
                if indexPath.section == 10 {
                    simpleMenuCell.titleLabel.text = "Sign out"
                    simpleMenuCell.titleLabel.textColor = .red
                    simpleMenuCell.titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
                }
                cell = simpleMenuCell
            
            case .premiumMenu:
                let premiumMenuCell = tableView.dequeueReusableCell(withIdentifier: PremiumMenuCell.reuseID) as! PremiumMenuCell
                cell = premiumMenuCell
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath == [6, 0] {
            if let user = user {
                if !user.isPremium {
                    PurchaseManager.shared.purchasePremium { (error) in
                        switch error {
                            case .failed:
                                self.view.makeToast("Purchase failed", duration: 2.0, position: .bottom)
                            case .success:
                                self.view.makeToast("Purchase successful", duration: 2.0, position: .bottom)
                                FirestoreManager.shared.fetchUser(uid: user.uid).then({ (user) in
                                    self.user = user
                                    self.tableView.reloadData()
                                })
                        }
                    }
                }
            }
        }
        if indexPath == [7, 0] {
            let userProfileFormViewController = UserProfileFormViewController()
            guard let user = user else { return }
            userProfileFormViewController.user = user
            userProfileFormViewController.profileViewControllerDelegate = self
            userProfileFormViewController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(userProfileFormViewController, animated: true)
        }
        if indexPath == [8, 0] {
            let imageGalleryViewController = ImagesViewController()
            guard let user = user else { return }
            imageGalleryViewController.user = user
            imageGalleryViewController.profileViewControllerDelegate = self
            imageGalleryViewController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(imageGalleryViewController, animated: true)
        }
        if indexPath == [9, 0] {
            PurchaseManager.shared.restore { (outcome) in
                switch outcome {
                    case .failed:
                        self.view.makeToast("Restore failed", duration: 1.0, position: .bottom)
                    case .nothingToRestore:
                        self.view.makeToast("Nothing to Restore", duration: 1.0, position: .bottom)
                    case .success:
                        self.view.makeToast("Restore success!", duration: 1.0, position: .bottom)
                    case .expired:
                        self.view.makeToast("Sorry, subscription expired", duration: 1.0, position: .bottom)
                }
            }
        }
        if indexPath == [10, 0] {
            self.showSignoutAlert(CTA: "Sign out")
        }
    }
}




/// Input Source to image using SDWebImage
@objcMembers
public class SDWebImageSource: NSObject, InputSource {
    /// url to load
    public var url: URL
    
    /// placeholder used before image is loaded
    public var placeholder: UIImage?
    
    /// Initializes a new source with a URL
    /// - parameter url: a url to be loaded
    /// - parameter placeholder: a placeholder used before image is loaded
    public init(url: URL, placeholder: UIImage? = nil) {
        self.url = url
        self.placeholder = placeholder
        super.init()
    }
    
    /// Initializes a new source with a URL string
    /// - parameter urlString: a string url to load
    /// - parameter placeholder: a placeholder used before image is loaded
    public init?(urlString: String, placeholder: UIImage? = nil) {
        if let validUrl = URL(string: urlString) {
            self.url = validUrl
            self.placeholder = placeholder
            super.init()
        } else {
            return nil
        }
    }
    
    public func load(to imageView: UIImageView, with callback: @escaping (UIImage?) -> Void) {
        imageView.sd_setImage(with: self.url, placeholderImage: self.placeholder, options: [], completed: { (image, _, _, _) in
            callback(image)
        })
    }
    
    public func cancelLoad(on imageView: UIImageView) {
        imageView.sd_cancelCurrentImageLoad()
    }
}


