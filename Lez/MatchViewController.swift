//
//  ViewController.swift
//  Lez
//
//  Created by Antonija Pek on 20/02/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import UIKit
import SnapKit
import moa
import Koloda
import Hero

class KolodaImage: UIImageView {
    var userImage = UIImageView()
    var userName = UILabel()
    var userLocation = UILabel()
    var gradientLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        layer.cornerRadius = 16
        clipsToBounds = true
        
        setupUserImage()
        setupUserName()
        setupLocation()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = userImage.bounds
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUserImage() {
        addSubview(userImage)
        userImage.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        userImage.contentMode = .scaleAspectFill
        userImage.clipsToBounds = true
        userImage.layer.cornerRadius = 16
    }
    
    func setupUserName() {
        addSubview(userName)
        userName.snp.setLabel("USERNAME_LABEL")
        userName.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(38)
        }
        userName.textColor = .white
        userName.textAlignment = .left
    }
    
    func setupLocation() {
        addSubview(userLocation)
        userLocation.snp.setLabel("LOCATION_LABEL")
        userLocation.snp.makeConstraints { (make) in
            make.left.right.equalTo(userName)
            make.top.equalTo(userName.snp.bottom)
        }
        userLocation.textColor = UIColor.white.withAlphaComponent(0.7)
        userLocation.textAlignment = .left
    }
    
    func activateShadow() {
        userImage.layer.addSublayer(gradientLayer)
        let black = UIColor.black.withAlphaComponent(0.5).cgColor
        gradientLayer.colors = [black, UIColor.clear.cgColor]
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 0.7)
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradientLayer.opacity = 1
    }
}

class MatchViewController: UIViewController, KolodaViewDelegate, KolodaViewDataSource {
    
    // MARK: - Variables
    var kolodaView = LezKolodaView()
    let userImage = UIImageView()
    var users: [User] = []
    var superview = UIView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for i in 1...10 {
            let newMatchingPreferences = MatchingPreferences(preferedAge: (23, 33))
            let newUser = User(id: i, name: "Antonija Pek \(i)", email: "user@gmail.com", age: 27, location: "New York", isOnboarded: true, isPremium: true, imageURL: "https://api.adorable.io/avatars/285/abott@adorable.png", matchingPreferences: newMatchingPreferences, userData: UserData(description: "I love IT, design and my wife and a cat.", dealBreakers: "Donald Trump supporter"))
            users.append(newUser)
        }

        setupKoloda()
    }
    
    // MARK: - Methods
    func setupKoloda() {
        kolodaView.dataSource = self
        kolodaView.delegate = self
        kolodaView.countOfVisibleCards = 3
        
        view.addSubview(kolodaView)
        
        kolodaView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 64, left: 32, bottom: 64, right: 32))
        }
        kolodaView.snp.setLabel("KOLODA_VIEW")
        kolodaView.hero.id = "GoFullscreen"
    }
}

extension MatchViewController {
    func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {
        let view = LezKolodaView()
        view.imageView.moa.url = users[index].imageURL
        view.imageView.moa.onSuccess = { image in
            view.locationLabel.text = self.users[index].location
            view.nameAndAgeLabel.text = "\(self.users[index].name!), \(self.users[index].age!)"
            view.addShadow()
            return image
        }
        return view
    }
    
    func kolodaShouldTransparentizeNextCard(_ koloda: KolodaView) -> Bool {
        return true
    }
    
    func kolodaShouldMoveBackgroundCard(_ koloda: KolodaView) -> Bool {
        return true
    }
    
    func kolodaDidRunOutOfCards(_ koloda: KolodaView) {
        koloda.reloadData()
    }
    
    func koloda(_ koloda: KolodaView, didSelectCardAt index: Int) {
        let nextViewController = CardFullscreenViewController()
//        self.navigationController?.push(nextViewController)
        nextViewController.user = self.users[index]
        self.present(nextViewController, animated: true, completion: nil)
    }
    
    func kolodaNumberOfCards(_ koloda: KolodaView) -> Int {
        return users.count
    }
    
    func kolodaSpeedThatCardShouldDrag(_ koloda: KolodaView) -> DragSpeed {
        return .default
    }
    
    func koloda(_ koloda: KolodaView, didShowCardAt index: Int) {
        print("Card \(index), \(String(describing: users[index].name))")
    }

    func koloda(_ koloda: KolodaView, draggedCardWithPercentage finishPercentage: CGFloat, in direction: SwipeResultDirection) {
//        print("Card dragged: \(finishPercentage), \(direction)")
        
        if direction == .right {
            
        } else if direction == .left {
            if finishPercentage >= 50 {

            }
        }
    }
}
