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

final class ProfileViewController: UIViewController, ProfileViewControllerDelegate {

    // MARK: - Variables

    private let tableView = UITableView()
    private let sections: [MenuSections] = [.profileImages, .headerCell, .titleWithDescription,
                                            .titleWithDescription, .titleWithDescription,
                                            .titleWithDescription, .simpleMenu, .simpleMenu,
                                            .simpleMenu, .simpleMenu, .simpleMenu, .simpleMenu]
    private var user: User?
    private let tabBar = UITabBar()
    private let hud = JGProgressHUD(style: .dark)
    private var jellyAnimator: JellyAnimator?
    private var refreshButton = PrimaryButton()

    // MARK: - View Lifecycle

    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshProfile),
                                               name: Notification.Name("UpdateProfile"), object: nil)
        setupTableView()
        setupRefreshButton()
        checkConnectivity()
    }

    // MARK: - Methods

    private func hideRefreshButton() {
        refreshButton.isHidden = true
    }

    private func showRefreshButton() {
        refreshButton.isHidden = false
    }

    @objc func refreshButtonTapped(_ sender: UIButton) {
        checkConnectivity()
    }

    private func checkConnectivity() {
        if Connectivity.isConnectedToInternet {
            hideRefreshButton()
            showTableView()
            refreshProfile()
        } else {
            Alertift.alert(title: "No Internet", message: "It seems you are not connected to network. Please try again.")
                .action(Alertift.Action.default("Okay"))
                .show(on: self) { self.hideTableView(); self.showRefreshButton() }
        }
    }

    @objc func refreshProfile() {
        startSpinner(title: "Loading Profile")
        guard let currentUser = Auth.auth().currentUser else { return }
        FirestoreManager.shared.fetchUser(uid: currentUser.uid).then { user in self.user = user }
            .then { _ in self.tableView.reloadData(); self.stopSpinner() }
    }

    private func hideTableView() {
        tableView.isHidden = true
    }

    private func showTableView() {
        tableView.isHidden = false
    }

    private func startSpinner(title: String) {
        // Start Animating
        hud.textLabel.text = title
        hud.vibrancyEnabled = true
        hud.interactionType = .blockAllTouches
        hud.show(in: view)
    }

    private func stopSpinner() {
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
                    if let image = sdWebImageSource { sources.append(image) }
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
                    print("User isPremium: \(user.isPremium)")
                    if user.isPremium || user.isManuallyPromoted {
                        simpleMenuCell.titleLabel.text = "You are Premium"
                    } else {
                        simpleMenuCell.titleLabel.text = "Get Premium"
                    }
                    simpleMenuCell.titleLabel.textColor = .black
//                    simpleMenuCell.titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
                } else if indexPath.section == 7 {
                    simpleMenuCell.titleLabel.text = "Edit Profile"
                    simpleMenuCell.titleLabel.textColor = .black
                    simpleMenuCell.isUserInteractionEnabled = true
                } else if indexPath.section == 8 {
                    simpleMenuCell.titleLabel.text = "Edit Images"
                    simpleMenuCell.isUserInteractionEnabled = true
                } else if indexPath.section == 9 {
                    simpleMenuCell.titleLabel.text = "Tracking for Analytics"
                    simpleMenuCell.isUserInteractionEnabled = true
                } else if indexPath.section == 10 {
                    if user.isPremium || user.isManuallyPromoted {
                        simpleMenuCell.titleLabel.text = "Restore Subscription"
                        simpleMenuCell.titleLabel.textColor = .gray
                        simpleMenuCell.isUserInteractionEnabled = false
                    } else {
                        simpleMenuCell.titleLabel.text = "Restore Subscription"
                        simpleMenuCell.titleLabel.textColor = .black
                        simpleMenuCell.isUserInteractionEnabled = true
                    }
                } else if indexPath.section == 11 {
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
                    PurchaseManager.purchase("premium") { (outcome) in
                        switch outcome {
                        case .failed:
                            self.view.makeToast("Purchase failed", duration: 2.0, position: .bottom)
                        case .success:
                            self.view.makeToast("Purchase successful", duration: 2.0, position: .bottom)
                        }
                    }
                }
            }
            highlightCell(indexPath: indexPath)
        }
        if indexPath == [7, 0] {
            let userProfileFormViewController = UserProfileFormViewController()
            guard let user = user else { return }
            userProfileFormViewController.user = user
            userProfileFormViewController.profileViewControllerDelegate = self
            userProfileFormViewController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(userProfileFormViewController, animated: true)
            highlightCell(indexPath: indexPath)
        }
        if indexPath == [8, 0] {
            let imageGalleryViewController = ImagesViewController()
            guard let user = user else { return }
            imageGalleryViewController.user = user
            imageGalleryViewController.profileViewControllerDelegate = self
            imageGalleryViewController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(imageGalleryViewController, animated: true)
            highlightCell(indexPath: indexPath)
        }
        if indexPath == [9, 0] {
            if DefaultsManager.shared.userWantsTracking() {
                Alertift.actionSheet(title: nil, message: "New GDPR law allows you to opt-out from analtytics tracking. You previously opted-out, you can change your mind if you want.")
                    .action(.destructive("Opt-in")) { action, int in
                        DefaultsManager.shared.saveTrackingPreference(value: false)
                    }
                    .action(.default("Cancel"))
                    .show(on: self)
            } else {
                Alertift.actionSheet(title: nil, message: "New GDPR law allows you to opt-out from analtytics tracking. We are not tracking anything shady, just regular stuff to make sure app works and that lesbians are enjoying using it.")
                    .action(.destructive("Opt-out")) { action, int in
                        DefaultsManager.shared.saveTrackingPreference(value: true)
                    }
                    .action(.default("Cancel"))
                    .show(on: self)
            }
            
            highlightCell(indexPath: indexPath)
        }
        if indexPath == [10, 0] {
            PurchaseManager.restorePurchase { outcome in
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
            highlightCell(indexPath: indexPath)
        }
        if indexPath == [11, 0] {
            self.showSignoutAlert(CTA: "Sign out")
            highlightCell(indexPath: indexPath)
        }
    }
}

extension ProfileViewController {
    func highlightCell(indexPath: IndexPath) {
        let currentCell = tableView.cellForRow(at: indexPath) as! SimpleMenuCell
        currentCell.backgroundColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.00)
        UIView.animate(withDuration: 1) { currentCell.backgroundColor = .white }
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
        }
        tableView.backgroundColor = .white
        tableView.separatorColor = .clear
        tableView.isUserInteractionEnabled = true
        let insets = UIEdgeInsets(top: -20, left: 0, bottom: 48, right: 0)
        tableView.contentInset = insets
        tableView.allowsMultipleSelection = false
        tableView.register(ProfileImagesCell.self, forCellReuseIdentifier: "ProfileImagesCell")
        tableView.register(TitleWithDescriptionCell.self, forCellReuseIdentifier: "TitleWithDescriptionCell")
        tableView.register(SimpleMenuCell.self, forCellReuseIdentifier: "SimpleMenuCell")
        tableView.register(IconMenuCell.self, forCellReuseIdentifier: "IconMenuCell")
        tableView.register(PremiumMenuCell.self, forCellReuseIdentifier: "PremiumMenuCell")
        tableView.register(HeaderCell.self, forCellReuseIdentifier: "HeaderCell")
        hideTableView()
    }

    private func setupRefreshButton() {
        view.addSubview(refreshButton)
        refreshButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(44)
            make.width.equalTo(150)
        }
        refreshButton.setTitle("Try Again", for: .normal)
        refreshButton.addTarget(self, action: #selector(self.refreshButtonTapped(_:)), for: .primaryActionTriggered)
        hideRefreshButton()
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
        imageView.sd_setImage(with: self.url, placeholderImage: self.placeholder, options: [],
                              completed: { (image, _, _, _) in callback(image) })
    }

    public func cancelLoad(on imageView: UIImageView) {
        imageView.sd_cancelCurrentImageLoad()
    }
}
