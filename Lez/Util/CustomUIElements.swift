//
//  CustomUIElements.swift
//  Lez
//
//  Created by Antonija on 14/05/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Foundation
import UIKit

class CustomProfileImageView: UIImageView {
    
    override func layoutSubviews() {
        backgroundColor = .white
        layer.borderWidth = 1
        layer.borderColor = UIColor(red:0.92, green:0.92, blue:0.92, alpha:1.00).cgColor
        layer.cornerRadius = frame.size.width / 2
        image = UIImage(named: "Add Image")
        layer.masksToBounds = true
        contentMode = .center
        clipsToBounds = true
    }
}

class CustomImageView: UIImageView {
    
    override func layoutSubviews() {
        backgroundColor = .white
        layer.borderWidth = 1
        layer.borderColor = UIColor(red:0.92, green:0.92, blue:0.92, alpha:1.00).cgColor
        layer.cornerRadius = 8
        image = UIImage(named: "Add Image")
        contentMode = .center
        clipsToBounds = true
    }
}

class CustomButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        layer.backgroundColor = UIColor(red:0.35, green:0.06, blue:0.68, alpha:1.00).cgColor
        layer.cornerRadius = 8
        for state: UIControlState in [.normal, .highlighted, .disabled, .selected, .focused, .application, .reserved] {
            setTitleColor(.black, for: state)
        }
        layer.backgroundColor = UIColor(red:0.45, green:0.96, blue:0.84, alpha:1.00).cgColor
        self.titleLabel?.font =  UIFont.systemFont(ofSize: 16, weight: .medium)
    }
}
