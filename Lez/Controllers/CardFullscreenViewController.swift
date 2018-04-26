//
//  CardFullscreenViewController.swift
//  Lez
//
//  Created by Antonija on 03/03/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import UIKit
import moa
import Auk
import Firebase

class CardFullscreenViewController: UIViewController {
    
    // MARK: - Variables
    let tableView = UITableView()
    let sections: [Sections] = [.profileImages, .headerCell, .titleWithDescription, .titleWithDescription, .titleWithDescription, .simpleMenu, .simpleMenu]
    var user: User?
    let closeButton = UIButton()
    let tabBar = UITabBar()

    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupCloseButton()
    }
    
    
    // MARK: - Methods
    
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
    
    @objc func closeButtonTapped(_ sender:UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
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
        switch sections[indexPath.section] {
            case.headerCell:
                let headerCell = tableView.dequeueReusableCell(withIdentifier: HeaderCell.reuseID) as! HeaderCell
                guard let user = user else { return UITableViewCell() }
                headerCell.titleLabel.text = user.name + ", " + "\(user.age)"
                headerCell.bodyLabel.text = "\(user.location.city)"
                cell = headerCell
            
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
                if indexPath.section == 5 {
                    simpleMenuCell.titleLabel.text = "Report"
                    simpleMenuCell.titleLabel.textColor = .red
                }
                if indexPath.section == 6 {
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
        print(indexPath)
        if indexPath == [5, 0] {
            guard let user = user else { return }
            guard let currentUser = Auth.auth().currentUser else { return }
            showReportActionSheet(report: user, reportOwner: currentUser.uid)
        }
        if indexPath == [6, 0] {
            showBlockActionSheet()
        }
    }
}
