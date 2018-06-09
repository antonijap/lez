//
//  GetPremiumController.swift
//  Lez
//
//  Created by Antonija on 04/05/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Foundation
import UIKit
import StoreKit
import SnapKit
import Alertift
import Firebase

class GetPremiumViewController: UIViewController {
    
    let closeButton = UIButton()
    let titleLabel = UILabel()
    let descriptionLabel = UILabel()
    let backgroundImageView = UIImageView()
    let buyButton = CustomButton()
    var matchViewControllerDelegate: MatchViewControllerDelegate?
    var priceString = "2.99€"
    
    var products = Set<SKProduct>() {
        didSet {
            setupInterface(with: products)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        fetchProducts()
    }
    
    // MARK: - Methods
    
    fileprivate func fetchProducts() {
        // Start Activity indicator
        
        PurchaseManager.fetchProducts { (products) in
            self.products = products
            
            // End Activity indicator
        }
    }
    
    fileprivate func setupInterface(with products: Set<SKProduct>) {
        let product = products.first
        
        view.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        backgroundImageView.image = UIImage(named: "Premium Background")
        backgroundImageView.contentMode = .scaleAspectFill
        
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(view.frame.height / 2.6)
            make.left.right.equalToSuperview()
        }
        titleLabel.text = "Get Premium"
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .heavy)
        
        view.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(40)
            make.right.equalToSuperview().inset(40)
        }
        descriptionLabel.text = "Unlimited matches for only \(product!.localizedPrice ?? priceString) per month."
        descriptionLabel.font = UIFont.systemFont(ofSize: 21, weight: .medium)
        descriptionLabel.numberOfLines = 2
        descriptionLabel.textAlignment = .center
        
        view.addSubview(buyButton)
        buyButton.snp.makeConstraints { (make) in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(32)
            make.left.equalToSuperview().offset(40)
            make.right.equalToSuperview().inset(40)
            make.height.equalTo(48)
        }
        buyButton.setTitle("Get Premium", for: .normal)
        buyButton.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        let buttonTap = UITapGestureRecognizer(target: self, action: #selector(self.buyTapped(_:)))
        buyButton.addGestureRecognizer(buttonTap)
        
        setupCloseButton()
    }

    fileprivate func setupCloseButton() {
        view.addSubview(closeButton)
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
    
    @objc func closeButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func buyTapped(_ sender: UIButton) {
      
        PurchaseManager.purchase("premium") { (outcome) in
            switch outcome {
            case .failed:
                Alertift.actionSheet(title: "Error ", message: "Something went wrong, purchase failed.")
                    .action(Alertift.Action.cancel("Okay"))
                    .show(on: self, completion: nil)
            case .success :
                self.dismiss(animated: true, completion: {
                    self.matchViewControllerDelegate?.refreshTableView()
                })
            }
        }
    }
    
}


