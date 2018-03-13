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

class CardFullscreenViewController: UIViewController {
    
    // MARK: - Variables
    
    let userImageView = UIImageView()
    var image = UIImage()
    var url = String()
    var scrollView = UIScrollView()
    var tableView = UITableView()
    var tableFakeView = UIView()
    
    
    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Hero.shared.defaultAnimation = .zoom
        setupScrollView()
        setupUserImage()
        setupFakeTableView()
//        viewDidLayoutSubviews()
    }
    
    
    // MARK: - Methods
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = self.view.bounds
    }
    
    func setupScrollView() {
        self.view.addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.width.equalToSuperview()
        }
        scrollView.contentSize = CGSize(width: view.bounds.width, height: 2000)
        scrollView.backgroundColor = .yellow
        scrollView.isDirectionalLockEnabled = true
        scrollView.isScrollEnabled = true
    }
    
    func setupFakeTableView() {
        self.view.addSubview(scrollView)
        tableFakeView.snp.makeConstraints { (make) in
            make.right.equalTo(0)
            make.top.equalTo(userImageView.snp.bottom)
            make.left.equalTo(0)
            make.height.equalTo(700)
        }
        tableFakeView.backgroundColor = .purple
    }
    
    func setupUserImage() {
        userImageView.moa.url = url
        scrollView.addSubview(userImageView)
        userImageView.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.width.equalToSuperview()
            make.bottom.equalTo(-100)
        }
        userImageView.image = image
        userImageView.hero.id = "goFullscreen"
        userImageView.hero.isEnabled = true
        userImageView.hero.modifiers = [.zPosition(0)]
        userImageView.contentMode = .scaleAspectFill
        userImageView.clipsToBounds = true
    }
}
