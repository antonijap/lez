//
//  FilterViewController.swift
//  Lez
//
//  Created by Antonija on 24/03/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import UIKit
import SnapKit

class FilterViewController: UIViewController {
    
    let closeButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCloseButton()
        view.backgroundColor = .white
    }
    
    func setupCloseButton() {
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { (make) in
            make.size.equalToSuperview()
            make.center.equalToSuperview()
        }
        closeButton.snp.setLabel("CLOSE_BUTTON")
        closeButton.setImage(UIImage(named: "Close"), for: .normal)
        closeButton.addTarget(self, action: #selector(self.closeButtonTapped), for:.touchUpInside)
    }
    
    @objc func closeButtonTapped(_ sender:UIButton) {
        dismiss(animated: true, completion: nil)
    }
}


