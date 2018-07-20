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

final class GetPremiumViewController: UIViewController {
    
    // MARK: - Properities
    
    private let closeButton = UIButton()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let backgroundImageView = UIImageView()
    private let buyButton = PrimaryButton()
    private var priceString = "2.99€"
    private let bureaucracyCrapButtonsView = UIView()
    private let privacyPolicyButton = UIButton()
    private let termsOfServiceButton = UIButton()
    private let subscriptionText = UILabel()
    var user: User!
    
    var matchViewControllerDelegate: MatchViewControllerDelegate?
    
    var products = Set<SKProduct>() {
        didSet { setupInterface(with: products) }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        fetchProducts()
    }
    
    // MARK: - Methods
    
    fileprivate func fetchProducts() {
        PurchaseManager.fetchProducts { products in self.products = products }
    }
    
    private func setupBureaucracyCrapButtons() {
        view.addSubview(bureaucracyCrapButtonsView)
        if Device.IS_4_7_INCHES_OR_LARGER() {
            bureaucracyCrapButtonsView.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.width.equalToSuperview().dividedBy(2)
                make.top.equalTo(buyButton.snp.bottom).offset(40)
            }
        } else {
            bureaucracyCrapButtonsView.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.width.equalToSuperview().dividedBy(1.7)
                make.top.equalTo(buyButton.snp.bottom).offset(40)
            }
        }
        
        bureaucracyCrapButtonsView.addSubview(privacyPolicyButton)
        privacyPolicyButton.snp.makeConstraints { make in make.leading.top.bottom.equalToSuperview() }
        privacyPolicyButton.setTitle("Privacy Policy", for: .normal)
        privacyPolicyButton.setTitleColor(.gray, for: .normal)
        privacyPolicyButton.addTarget(self, action: #selector(self.privacyPolicyButtontapped), for: .primaryActionTriggered)
        privacyPolicyButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .regular)
        
        bureaucracyCrapButtonsView.addSubview(termsOfServiceButton)
        termsOfServiceButton.snp.makeConstraints { make in make.trailing.top.bottom.equalToSuperview() }
        termsOfServiceButton.setTitle("Terms of Service", for: .normal)
        termsOfServiceButton.setTitleColor(.gray, for: .normal)
        termsOfServiceButton.addTarget(self, action: #selector(self.termsOfServiceButtontapped), for: .primaryActionTriggered)
        termsOfServiceButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .regular)
        
        view.addSubview(subscriptionText)
        subscriptionText.snp.makeConstraints { make in
            make.top.equalTo(bureaucracyCrapButtonsView.snp.bottom).offset(40)
            make.leading.equalToSuperview().inset(32)
            make.trailing.equalToSuperview().inset(32)
        }
        subscriptionText.text = "Premium is monthly auto-renewable subscription of Lez and it offers subscription with price €2.99 per month. Payment will be charged to iTunes Account at confirmation of purchase. Subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period. Account will be charged for renewal within 24-hours prior to the end of the current period. Subscriptions may be managed by the user and auto-renewal may be turned off by going to the iPhone’s settings."
        subscriptionText.numberOfLines = 20
        subscriptionText.font = .systemFont(ofSize: 9, weight: .regular)
        subscriptionText.textColor = .gray
    }
    
    @objc private func privacyPolicyButtontapped() {
        if let url = URL(string: "https://www.iubenda.com/privacy-policy/89963959") {
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    @objc private func termsOfServiceButtontapped() {
        if let url = URL(string: "https://www.iubenda.com/privacy-policy/89963959") {
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    private func setupInterface(with products: Set<SKProduct>) {
        let product = products.first
        
        view.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        backgroundImageView.image = #imageLiteral(resourceName: "Premium Background")
        backgroundImageView.contentMode = .scaleAspectFill
        
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(view.frame.height / 2.6)
            make.leading.trailing.equalToSuperview()
        }
        titleLabel.text = "Get Premium"
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 28, weight: .heavy)
        
        view.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(40)
            make.trailing.equalToSuperview().inset(40)
        }
        descriptionLabel.text = "Unlimited matches for only \(product!.localizedPrice ?? priceString) per month."
        descriptionLabel.font = .systemFont(ofSize: 21, weight: .medium)
        descriptionLabel.numberOfLines = 2
        descriptionLabel.textAlignment = .center
        
        view.addSubview(buyButton)
        buyButton.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(32)
            make.leading.equalToSuperview().offset(40)
            make.trailing.equalToSuperview().inset(40)
            make.height.equalTo(48)
        }
        buyButton.setTitle("Get Premium", for: .normal)
        buyButton.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        let buttonTap = UITapGestureRecognizer(target: self, action: #selector(self.buyTapped(_:)))
        buyButton.addGestureRecognizer(buttonTap)
        
        setupCloseButton()
        setupBureaucracyCrapButtons()
    }

    private func setupCloseButton() {
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.width.equalTo(32)
            make.height.equalTo(32)
            make.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(32)
        }
        let image = #imageLiteral(resourceName: "Close")
        closeButton.setImage(image, for: .normal)
        closeButton.addTarget(self, action: #selector(self.closeButtonTapped(_:)), for: .primaryActionTriggered)
    }
    
    @objc func closeButtonTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @objc func buyTapped(_ sender: UIButton) {
        PurchaseManager.purchase("premium") { outcome in
            switch outcome {
            case .failed:
                Alertift.actionSheet(title: "Error ", message: "Something went wrong, purchase failed.")
                    .action(Alertift.Action.cancel("Okay"))
                    .show(on: self)
            case .success:
                self.dismiss(animated: true) { AnalyticsManager.shared.logEvent(name: .userPurchasedPremium, user: self.user) }
            }
        }
    }
    
}


