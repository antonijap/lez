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
    case titleWithIcon
}

class UserImages: UITableViewCell {
//    let imageView: UIImageView?
    
//    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        imageView.image = image
//        imageView.hero.id = "goFullscreen"
//        imageView.hero.isEnabled = true
//        imageView.hero.modifiers = [.zPosition(0)]
//        imageView.contentMode = .scaleAspectFill
//        imageView.clipsToBounds = true
//    }
//    func setupUserImage() {
//        imageView.moa.url = url
//        imageView.snp.makeConstraints { (make) in
//            make.top.equalTo(0)
//            make.width.equalToSuperview()
//            make.height.equalTo(imageView.snp.width).multipliedBy(1.4)
//        }
//
//    }
}

class TitleWithDescriptionCell: UITableViewCell {
    let reuseID = "TitleWithDescriptionCell"
    var titleLabel = UILabel()
    var bodyLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.backgroundColor = UIColor.cyan
        self.isUserInteractionEnabled = false
    
        self.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(16)
            make.left.equalTo(8)
            make.right.equalTo(-8)
        }
        titleLabel.textColor = .black
        titleLabel.isUserInteractionEnabled = false
        titleLabel.text = "Title"
        
        self.contentView.addSubview(bodyLabel)
        bodyLabel.snp.makeConstraints { (make) in
            make.left.equalTo(8)
            make.right.equalTo(-8)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
        }
        bodyLabel.backgroundColor = .yellow
        bodyLabel.numberOfLines = 5
        bodyLabel.text = "The code above is pretty straightforward: you dequeue a cell, set its information and a text color, and then return the cell."
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
}

class CardFullscreenViewController: UIViewController {
    
    // MARK: - Variables
    
    let userImageView = UIImageView()
    var image = UIImage()
    var url = String()
    var tableView = UITableView()
    var sections: [Sections] = []
    var user: User?
    
    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sections = [.titleWithDescription, .titleWithDescription]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Hero.shared.defaultAnimation = .zoom
        setupTableView()
    }
    
    
    // MARK: - Methods
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TitleWithDescriptionCell.self, forCellReuseIdentifier: "TitleWithDescriptionCell")
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.size.equalToSuperview()
        }
        tableView.backgroundColor = .white
        tableView.separatorColor = .black
        tableView.isUserInteractionEnabled = true
        tableView.rowHeight = UITableViewAutomaticDimension
//        tableView.rowHeight = 140
        tableView.estimatedRowHeight = 140
    }
}

extension CardFullscreenViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TitleWithDescriptionCell") as! TitleWithDescriptionCell
        switch sections[indexPath.section] {
            case .titleWithDescription:
                print("titleWithDescription")
                if indexPath.section == 0 {
                    cell.bodyLabel.text = "Lorem ipsum dolor sit amet."
                }
                return cell
            case .titleWithIcon:
                print("titleWithDescription")
                return cell
        }
    }
}
