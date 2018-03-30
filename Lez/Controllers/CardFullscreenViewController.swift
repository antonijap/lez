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

enum Sections {
    case titleWithDescription
    case profileImages
    case simpleMenu
    case iconMenu
}

protocol ReuseIdentifiable {
    static var reuseID: String { get }
}

extension ProfileImagesCell: ReuseIdentifiable {
    static var reuseID: String { return String(describing: self) }
}

extension TitleWithDescriptionCell: ReuseIdentifiable {
    static var reuseID: String { return String(describing: self) }
}

extension SimpleMenuCell: ReuseIdentifiable {
    static var reuseID: String { return String(describing: self) }
}

extension IconMenuCell: ReuseIdentifiable {
    static var reuseID: String { return String(describing: self) }
}

class IconMenuCell: UITableViewCell {
    
    let iconImageView = UIImageView()
    let titleLabel = UILabel()
    let separatorView = UIView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupIconImageView()
        setupTitleLabel()
        setupSeparatorView()
    }
    
    func setupSeparatorView() {
        addSubview(separatorView)
        separatorView.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.left.equalToSuperview().inset(24)
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
            make.top.equalTo(iconImageView.snp.bottom).offset(16)
        }
        separatorView.backgroundColor = UIColor(red:0.94, green:0.94, blue:0.94, alpha:1.00)
    }
    
    func setupIconImageView() {
        addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (make) in
            make.size.equalTo(24)
            make.left.equalToSuperview().inset(24)
            make.top.equalToSuperview().offset(24)
        }
    }
    
    func setupTitleLabel() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconImageView.snp.right).offset(8)
            make.centerY.equalTo(iconImageView)
        }
        titleLabel.text = "Label"
        titleLabel.textColor = UIColor(red:0.59, green:0.59, blue:0.59, alpha:1.00)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SimpleMenuCell: UITableViewCell {

    let titleLabel = UILabel()
    let separatorView = UIView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupTitleLabelNoIcon()
        setupSeparatorView()
    }

    func setupTitleLabelNoIcon() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(32)
            make.top.equalToSuperview().offset(16)
        }
        titleLabel.text = "Label"
        titleLabel.textColor = .red
    }
    
    func setupSeparatorView() {
        addSubview(separatorView)
        separatorView.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.left.equalToSuperview().inset(24)
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
        }
        separatorView.backgroundColor = UIColor(red:0.94, green:0.94, blue:0.94, alpha:1.00)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ProfileImagesCell: UITableViewCell {
    var scrollView = UIScrollView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupScrollView()
        layoutIfNeeded()
    }
    
    private func setupScrollView() {
        addSubview(scrollView)
        let x = frame.width * 1.6
        scrollView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(x)
            make.bottom.equalToSuperview().inset(16).priority(999)
        }
        scrollView.snp.setLabel("SCROLL_VIEW")
        scrollView.auk.settings.contentMode = .scaleAspectFill
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TitleWithDescriptionCell: UITableViewCell {
    var titleLabel = UILabel()
    var bodyLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 32, bottom: 0, right: 32))
        }
        titleLabel.textColor = .black
        titleLabel.text = "Title not set."
        titleLabel.textColor = UIColor(red:0.59, green:0.59, blue:0.59, alpha:1.00)
        
        addSubview(bodyLabel)
        bodyLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(32)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.bottom.equalToSuperview().offset(-16)
        }
        bodyLabel.numberOfLines = 5
        bodyLabel.text = "Ooops. Not set."
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
}

class CardFullscreenViewController: UIViewController {
    
    // MARK: - Variables
    let tableView = UITableView()
    let sections: [Sections] = [.profileImages, .titleWithDescription, .titleWithDescription, .titleWithDescription, .titleWithDescription, .iconMenu, .simpleMenu, .simpleMenu]
    var user: User?
    let closeButton = UIButton()
    let tabBar = UITabBar()

    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        hero.isEnabled = true
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
            case .titleWithDescription:
                let titleWithDescriptionCell = tableView.dequeueReusableCell(withIdentifier: TitleWithDescriptionCell.reuseID) as! TitleWithDescriptionCell
                if indexPath.section == 1 {
                    titleWithDescriptionCell.titleLabel.textColor = .black
                    titleWithDescriptionCell.titleLabel.font = UIFont.systemFont(ofSize: 21.0)
                    titleWithDescriptionCell.titleLabel.text = user!.name + ", " + "\(user?.age ?? 0)"
                    titleWithDescriptionCell.bodyLabel.text = "\(user!.location.city)"
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
                    titleWithDescriptionCell.titleLabel.text = "About"
                    titleWithDescriptionCell.bodyLabel.text = user?.details.about
                }
                if indexPath.section == 4 {
                    titleWithDescriptionCell.titleLabel.text = "Dealbreakers"
                    titleWithDescriptionCell.bodyLabel.text = user?.details.dealBreakers
                }
                cell = titleWithDescriptionCell
            case .profileImages:
                let profileImagesCell = tableView.dequeueReusableCell(withIdentifier: ProfileImagesCell.reuseID) as! ProfileImagesCell
                let url = user?.images?.imageURLs
                for u in url! {
                   profileImagesCell.scrollView.auk.show(url: u)
                }
                cell = profileImagesCell
            case .iconMenu:
                let iconMenuCell = tableView.dequeueReusableCell(withIdentifier: IconMenuCell.reuseID) as! IconMenuCell
                if indexPath.section == 5 {
                    // Check if verified
                    iconMenuCell.titleLabel.text = "Unverified Profile"
                    iconMenuCell.iconImageView.image = UIImage(named: "Unverified")
                }
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
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath)
        if indexPath == [6, 0] {
            showReportActionSheet()
        }
        if indexPath == [7, 0] {
            showBlockActionSheet()
        }
    }
}
