//
//  CardFullscreenViewController.swift
//  Lez
//
//  Created by Antonija on 03/03/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import UIKit
import Hero

class CardFullscreenViewController: UIViewController {
    
    let demoView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        demoView.hero.id = "goFullscreen"
        demoView.hero.isEnabled = true
        
        self.view.addSubview(demoView)
        demoView.snp.makeConstraints { (make) in
            make.right.equalTo(0)
            make.height.equalTo(self.view.bounds.height / 2)
            make.left.equalTo(0)
            make.bottom.equalTo(0)
        }
        demoView.backgroundColor = .black
    }

}
