//
//  CardFullscreenViewController.swift
//  Lez
//
//  Created by Antonija on 03/03/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import UIKit
import Hero
import moa

enum Sections {
    case titleWithDescription
    case profileImages
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

class ProfileImagesCell: UITableViewCell {
    var profileImageView = UIImageView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUserImage()
    }
    
    private func setupUserImage() {
        addSubview(profileImageView)
        profileImageView.snp.setLabel("PROFILE_IMAGE_VIEW")
        profileImageView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(500)
            make.bottom.equalToSuperview().inset(16)
        }
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        selectionStyle = .none
        profileImageView.hero.id = "GoFullscreen"
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
    let sections: [Sections] = [.profileImages, .titleWithDescription, .titleWithDescription, .titleWithDescription, .titleWithDescription]
    var user: User?
    let closeButton = UIButton()
    

    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        hero.isEnabled = true
        setupTableView()
        setupCloseButton()
        let images: [UIImage] = [UIImage(named: "Taylor")!, UIImage(named: "Taylor")!, UIImage(named: "Taylor")!]
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
            make.size.equalToSuperview()
        }
        tableView.backgroundColor = .white
        tableView.separatorColor = .clear
        tableView.isUserInteractionEnabled = true
        
        tableView.register(ProfileImagesCell.self, forCellReuseIdentifier: "ProfileImagesCell")
        tableView.register(TitleWithDescriptionCell.self, forCellReuseIdentifier: "TitleWithDescriptionCell")
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
                    titleWithDescriptionCell.titleLabel.text = user!.name! + ", " + "\(user?.age ?? 0)"
                    titleWithDescriptionCell.bodyLabel.text = "\(user!.location ?? "No Data")"
                }
                if indexPath.section == 2 {
                    titleWithDescriptionCell.titleLabel.text = "I am here for"
                    titleWithDescriptionCell.bodyLabel.text = "Relationship, Friendship"
                }
                if indexPath.section == 3 {
                    titleWithDescriptionCell.titleLabel.text = "About"
                    titleWithDescriptionCell.bodyLabel.text = "I am this and that. More about me goes here. Hope you have fun."
                }
                if indexPath.section == 4 {
                    titleWithDescriptionCell.titleLabel.text = "Dealbreakers"
                    titleWithDescriptionCell.bodyLabel.text = "Dicks and Trump"
                }
                cell = titleWithDescriptionCell
            case .profileImages:
                let profileImagesCell = tableView.dequeueReusableCell(withIdentifier: ProfileImagesCell.reuseID) as! ProfileImagesCell
                profileImagesCell.profileImageView.moa.url = user?.imageURL
                cell = profileImagesCell
        }
        return cell
    }
}
