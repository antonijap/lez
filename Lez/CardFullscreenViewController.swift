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
    var fakeTableView = UIView()
    
    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Hero.shared.defaultAnimation = .zoom
        setupScrollView()
        setupUserImage()
        setupFakeTableView()
    }
    
    
    // MARK: - Methods
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = self.view.bounds
    }
    
    func setupScrollView() {
        self.view.addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }
        scrollView.backgroundColor = .yellow
        scrollView.isDirectionalLockEnabled = true
        scrollView.isScrollEnabled = true
    }
    
    func contentHeight() -> CGFloat {
        let result = userImageView.frame.height + tableView.frame.height
        print("Height will be: \(userImageView.frame.height)")
        return result
    }
    
    func setupFakeTableView() {
        scrollView.addSubview(fakeTableView)
        fakeTableView.snp.makeConstraints { (make) in
            make.top.equalTo(userImageView.snp.bottom)
            make.width.equalToSuperview()
            make.height.equalTo(700)
            make.bottom.equalTo(scrollView)
        }
        fakeTableView.backgroundColor = .purple
    }
    
    func setupUserImage() {
        userImageView.moa.url = url
        scrollView.addSubview(userImageView)
        userImageView.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.width.equalToSuperview()
            make.height.equalTo(userImageView.snp.width).multipliedBy(1.4)
        }
        userImageView.image = image
        userImageView.hero.id = "goFullscreen"
        userImageView.hero.isEnabled = true
        userImageView.hero.modifiers = [.zPosition(0)]
        userImageView.contentMode = .scaleAspectFill
        userImageView.clipsToBounds = true
    }
}
