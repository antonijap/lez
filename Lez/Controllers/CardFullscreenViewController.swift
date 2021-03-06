//
//  CardFullscreenViewController.swift
//  Lez
//
//  Created by Antonija on 03/03/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import UIKit
import Firebase

final class CardFullscreenViewController: UIViewController {
    
    // MARK: - Variables
    private let tableView = UITableView()
    private let sections: [MenuSections] = [.profileImages, .headerCell, .titleWithDescription,
                                            .titleWithDescription, .titleWithDescription, .titleWithDescription,
                                            .simpleMenu, .simpleMenu]
    var user: User?
    private let closeButton = UIButton()
    private let tabBar = UITabBar()
    var delegate: MatchViewControllerDelegate?
    var me: User?
    var indexPath: IndexPath!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupCloseButton()
    }

    // MARK: - Methods

    func setupCloseButton() {
        view.insertSubview(closeButton, aboveSubview: tableView)
        closeButton.snp.makeConstraints { make in
            make.size.equalTo(32)
            make.right.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(32)
        }
        closeButton.setImage(#imageLiteral(resourceName: "Close"), for: .normal)
        closeButton.addTarget(self, action: #selector(self.closeButtonTapped(_:)), for: .primaryActionTriggered)
    }

    @objc func closeButtonTapped(_ sender:UIButton) {
        dismiss(animated: true)
    }

    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        tableView.backgroundColor = .white
        tableView.separatorColor = .clear
        tableView.isUserInteractionEnabled = true
        let insets = UIEdgeInsets(top: -20, left: 0, bottom: 48, right: 0)
        tableView.contentInset = insets
        tableView.register(ProfileImagesCell.self, forCellReuseIdentifier: "ProfileImagesCell")
        tableView.register(TitleWithDescriptionCell.self, forCellReuseIdentifier: "TitleWithDescriptionCell")
        tableView.register(SimpleMenuCell.self, forCellReuseIdentifier: "SimpleMenuCell")
        tableView.register(IconMenuCell.self, forCellReuseIdentifier: "IconMenuCell")
        tableView.register(HeaderCell.self, forCellReuseIdentifier: "HeaderCell")
    }
}

extension CardFullscreenViewController: UITableViewDelegate, UITableViewDataSource {
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
        guard let user = user else { return UITableViewCell() }
        switch sections[indexPath.section] {
            case.headerCell:
                let headerCell = tableView.dequeueReusableCell(withIdentifier: HeaderCell.reuseID) as! HeaderCell
                headerCell.titleLabel.text = user.name + ", " + "\(user.age)"
                headerCell.bodyLabel.text = "\(user.location.city), \(user.location.country)"
                cell = headerCell
            case .titleWithDescription:
                let titleWithDescriptionCell = tableView.dequeueReusableCell(withIdentifier: TitleWithDescriptionCell.reuseID) as! TitleWithDescriptionCell
                if indexPath.section == 1 {
                    titleWithDescriptionCell.titleLabel.textColor = .black
                    titleWithDescriptionCell.titleLabel.font = UIFont.systemFont(ofSize: 21.0)
                    titleWithDescriptionCell.titleLabel.text = user.name + ", " + "\(user.age)"
                    titleWithDescriptionCell.bodyLabel.text = "\(user.location.city)"
                    titleWithDescriptionCell.bodyLabel.snp.remakeConstraints { make in
                        make.leading.trailing.equalToSuperview().inset(32)
                        make.top.equalTo(titleWithDescriptionCell.titleLabel.snp.bottom)
                        make.bottom.equalToSuperview().offset(-16)
                    }
                }
                if indexPath.section == 2 {
                    titleWithDescriptionCell.titleLabel.text = "I am here for"
                    let string = user.preferences.lookingFor.joined(separator: ", ")
                    titleWithDescriptionCell.bodyLabel.text = string
                }
                if indexPath.section == 3 {
                    titleWithDescriptionCell.titleLabel.text = "About"
                    titleWithDescriptionCell.bodyLabel.text = user.details.about
                }
                if indexPath.section == 4 {
                    titleWithDescriptionCell.titleLabel.text = "Dealbreakers"
                    titleWithDescriptionCell.bodyLabel.text = user.details.dealBreakers
                }
                if indexPath.section == 5 {
                    titleWithDescriptionCell.titleLabel.text = "Diet"
                    titleWithDescriptionCell.bodyLabel.text = user.details.diet.rawValue
                }
                cell = titleWithDescriptionCell
            case .profileImages:
                let profileImagesCell = tableView.dequeueReusableCell(withIdentifier: ProfileImagesCell.reuseID) as! ProfileImagesCell
                profileImagesCell.slideshow.setImageInputs([])
                var sources: [SDWebImageSource] = []
                for image in user.images {
                    let sdWebImageSource = SDWebImageSource(urlString: image.url)
                    sources.append(sdWebImageSource!)
                }
                profileImagesCell.slideshow.setImageInputs(sources)
                cell = profileImagesCell
            case .iconMenu:
                let iconMenuCell = tableView.dequeueReusableCell(withIdentifier: IconMenuCell.reuseID) as! IconMenuCell
                cell = iconMenuCell
            case .simpleMenu:
                let simpleMenuCell = tableView.dequeueReusableCell(withIdentifier: SimpleMenuCell.reuseID) as! SimpleMenuCell
                if indexPath.section == 6 {
                    simpleMenuCell.titleLabel.text = "Report"
                    simpleMenuCell.titleLabel.textColor = .red
                }
                if indexPath.section == 7 {
                    simpleMenuCell.titleLabel.text = "Block User"
                    simpleMenuCell.titleLabel.textColor = .black
                }
                cell = simpleMenuCell
            case .premiumMenu:
                let premiumMenuCell = tableView.dequeueReusableCell(withIdentifier: PremiumMenuCell.reuseID) as! PremiumMenuCell
                cell = premiumMenuCell
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let currentUser = Auth.auth().currentUser else { return }
        guard let fullscreenUser = user else { return }

        if indexPath == [6, 0] {
            showReportActionSheet(report: fullscreenUser, reportOwner: currentUser.uid)
            AnalyticsManager.shared.logEvent(name: AnalyticsEvents.userReportedSomebody, user: self.me!)
        }
        if indexPath == [7, 0] {
            FirestoreManager.shared.fetchUser(uid: currentUser.uid).then { (user) in
                self.showBlockActionSheet(currentUser: user, blockedUser: fullscreenUser.uid) {
                    AnalyticsManager.shared.logEvent(name: AnalyticsEvents.userBlockedSomebody, user: self.me!)
                    self.delegate?.removeUserFromLocalArray(uid: fullscreenUser.uid)
                }
            }
        }
    }
}
