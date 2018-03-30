//
//  LezKolodaView.swift
//  Lez
//
//  Created by Antonija Pek on 22/03/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import UIKit
import Koloda


let defaultTopOffset: CGFloat = 0
let defaultHorizontalOffset: CGFloat = 0
let defaultHeightRatio: CGFloat = 1.90

class LezKolodaView: KolodaView {
    let imageView = UIImageView()
    let nameAndAgeLabel = UILabel()
    let locationLabel = UILabel()
    let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
                
        addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 16
        imageView.clipsToBounds = true
        
        addSubview(locationLabel)
        locationLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
        }
        locationLabel.textColor = .white
        
        addSubview(nameAndAgeLabel)
        nameAndAgeLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(16)
            make.bottom.equalTo(locationLabel.snp.top).offset(-3)
        }
        nameAndAgeLabel.textColor = .white
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = imageView.bounds
    }
    
    func addShadow() {
        imageView.layer.addSublayer(gradientLayer)
        let black = UIColor.black.withAlphaComponent(0.5).cgColor
        gradientLayer.colors = [black, UIColor.clear.cgColor]
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 0.7)
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradientLayer.opacity = 1
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

