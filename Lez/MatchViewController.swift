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
    let likeImageView = UIImageView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Love Room"
        let filterButton = UIButton(type: .custom)
        filterButton.setImage(UIImage(named: "Filter"), for: .normal)
        filterButton.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        filterButton.addTarget(self, action: #selector(self.showFilters), for: .touchUpInside)
        let rightItem = UIBarButtonItem(customView: filterButton)
        navigationItem.setRightBarButtonItems([rightItem], animated: true)
        navigationController?.navigationBar.backgroundColor = .white
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()

        
        let user1 = User(id: 334, name: "Antonija Pek", email: "user@gmail.com", age: 27, location: "New York", isOnboarded: true, isPremium: true, matchingPreferences: MatchingPreferences(preferedAge: (23, 33)), userData: UserData(about: "I love IT, design and my wife and a cat.", dealBreakers: "When people interrupt me."), userImages: UserImages(imageURLs: ["https://picsum.photos/1000/700/?random", "https://picsum.photos/1000/700/?random", "https://picsum.photos/1000/700/?random"]))
        users.append(user1)
        
        let user2 = User(id: 334, name: "Antonija Kasum", email: "user@gmail.com", age: 30, location: "New York", isOnboarded: true, isPremium: true, matchingPreferences: MatchingPreferences(preferedAge: (23, 33)), userData: UserData(about: "I like nails!", dealBreakers: "When people are stupid and loud."), userImages: UserImages(imageURLs: ["https://picsum.photos/1000/700/?random", "https://picsum.photos/1000/700/?random", "https://picsum.photos/1000/700/?random"]))
        users.append(user2)
        
        let user3 = User(id: 334, name: "Mimi Kasum-Pek", email: "user@gmail.com", age: 27, location: "New York", isOnboarded: true, isPremium: true, matchingPreferences: MatchingPreferences(preferedAge: (23, 33)), userData: UserData(about: "Meee meee meeeeeeee", dealBreakers: "Me me"), userImages: UserImages(imageURLs: ["https://picsum.photos/1000/700/?random", "https://picsum.photos/1000/700/?random", "https://picsum.photos/1000/700/?random"]))
        users.append(user3)

        setupKoloda()
    }
    
    // MARK: - Methods
    func setupKoloda() {
        kolodaView.dataSource = self
        kolodaView.delegate = self
        kolodaView.countOfVisibleCards = 3
        
        view.addSubview(kolodaView)
        
        kolodaView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin).inset(24)
            make.width.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8))
            make.centerX.equalToSuperview()
        }
        kolodaView.snp.setLabel("KOLODA_VIEW")
        kolodaView.hero.id = "GoFullscreen"
    }
    
    @objc func showFilters() {
        print("Filters")
        let nextViewController = FilterViewController()
        present(nextViewController, animated: true, completion: nil)
    }
}

extension MatchViewController {
    func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {
        let view = LezKolodaView()
        view.imageView.moa.url = users[index].userImages?.imageURLs?.first
        view.imageView.moa.onSuccess = { image in
            view.locationLabel.text = self.users[index].location
            view.nameAndAgeLabel.text = "\(self.users[index].name!), \(self.users[index].age!)"
            view.addShadow()
            return image
        }
        return view
    }
    
    func kolodaShouldTransparentizeNextCard(_ koloda: KolodaView) -> Bool {
        return false
    }
    
    func kolodaShouldMoveBackgroundCard(_ koloda: KolodaView) -> Bool {
        return true
    }
    
    func kolodaDidRunOutOfCards(_ koloda: KolodaView) {
        kolodaView.reloadData()
    }
    
    func koloda(_ koloda: KolodaView, didSelectCardAt index: Int) {
        let nextViewController = CardFullscreenViewController()
//        self.navigationController?.push(nextViewController)
        nextViewController.user = self.users[index]
        present(nextViewController, animated: true, completion: nil)
    }
    
    func kolodaNumberOfCards(_ koloda: KolodaView) -> Int {
        return users.count
    }
    
    func kolodaSpeedThatCardShouldDrag(_ koloda: KolodaView) -> DragSpeed {
        return .fast
    }
    
    func koloda(_ koloda: KolodaView, didShowCardAt index: Int) {
        print("Card \(index), \(String(describing: users[index].name))")
    }

    func koloda(_ koloda: KolodaView, draggedCardWithPercentage finishPercentage: CGFloat, in direction: SwipeResultDirection) {
        if direction == .right {
            
        } else if direction == .left {
            if finishPercentage >= 50 {

            }
        }
    }
    
    func koloda(_ koloda: KolodaView, viewForCardOverlayAt index: Int) -> OverlayView? {
        let cardOverlay = CardOverlay(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
        return cardOverlay
    }
}

class CardOverlay: OverlayView {
    let overlayView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(overlayView)
        overlayView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        overlayView.backgroundColor = UIColor.green.withAlphaComponent(0.2)
        overlayView.layer.cornerRadius = 16
        overlayView.clipsToBounds = true
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var overlayState: SwipeResultDirection?  {
        didSet {
            switch overlayState {
            case .left? :
                overlayView.backgroundColor = UIColor.red.withAlphaComponent(0.2)
            case .right? :
                overlayView.backgroundColor = UIColor.green.withAlphaComponent(0.2)
            default:
                overlayView.backgroundColor = .clear
            }
            
        }
    }
}
