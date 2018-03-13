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

class Like: UIView {
    override func draw(_ rect: CGRect) {
        let rect = CGRect(x: 0.0, y: 0.0, width: 70, height: 70)
        LezIcons.drawLike(frame: rect, resizing: .aspectFit)
    }
}

class KolodaCardView: UIView {
    var helloWorld = "Hello World"
    var userImage = UIImageView()
    var userName = UILabel()
    var userLocation = UILabel()
    var parent = UIView()
    var gradientLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        parent = self
        parent.backgroundColor = .clear
        parent.layer.cornerRadius = 16
        parent.clipsToBounds = true
        
        setupUserImage()
        setupUserName()
        setupLocation()
        setupHero()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = userImage.bounds
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupHero() {
        self.hero.id = "goFullscreen"
        self.hero.isEnabled = true
        self.hero.modifiers = [.fade]
    }
    
    func setupUserImage() {
        parent.addSubview(userImage)
        userImage.snp.makeConstraints { make in
            make.top.equalTo(parent)
            make.bottom.equalTo(parent)
            make.left.equalTo(parent)
            make.right.equalTo(parent)
        }
        userImage.contentMode = .scaleAspectFill
        userImage.clipsToBounds = true
        userImage.layer.cornerRadius = 16
    }
    
    func setupUserName() {
        parent.addSubview(userName)
        userName.snp.makeConstraints { (make) in
            make.left.equalTo(parent).offset(16)
            make.right.equalTo(parent)
            make.height.equalTo(20)
            make.bottom.equalTo(-38)
        }
        userName.textColor = .white
        userName.textAlignment = .left
    }
    
    func setupLocation() {
        parent.addSubview(userLocation)
        userLocation.snp.makeConstraints { (make) in
            make.left.equalTo(parent).offset(16)
            make.right.equalTo(parent)
            make.height.equalTo(20)
            make.bottom.equalTo(-16)
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
    var kolodaView = KolodaView()
    let userImage = UIImageView()
    var users: [User] = []
    var superview = UIView()
    let like = Like()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        superview = self.view
        
//        superview.addSubview(like)
//        like.snp.makeConstraints { (make) in
//            make.width.equalTo(80)
//            make.height.equalTo(80)
//            make.left.equalTo(10)
//            make.top.equalTo(10)
//        }
//        like.backgroundColor = .clear
        
        for i in 1...10 {
            let newMatchingPreferences = MatchingPreferences(preferedAge: (23, 33))
            let newUser = User(id: i, name: "User \(i)", email: "user@gmail.com", age: 27, location: "New York", isOnboarded: true, isPremium: true, imageURL: "https://beebom.com/wp-content/uploads/2016/01/Reverse-Image-Search-Engines-Apps-And-Its-Uses-2016.jpg", matchingPreferences: newMatchingPreferences)
            users.append(newUser)
        }

        setupKoloda()
    }
    
    // MARK: - Methods
    func setupKoloda() {
        kolodaView.dataSource = self
        kolodaView.delegate = self
        kolodaView.countOfVisibleCards = 1
        
        view.addSubview(kolodaView)
        
        kolodaView.snp.makeConstraints { (make) in
            make.left.equalTo(32)
            make.right.equalTo(-32)
            make.top.equalTo(67)
            make.bottom.equalTo(-64)
        }
    }
}

extension MatchViewController {
    func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {
        let view = KolodaCardView()
        view.userImage.moa.url = users[index].imageURL
        view.userImage.moa.onSuccess = { image in
            view.activateShadow()
            view.userName.text = "\(self.users[index].name!), \(self.users[index].age!)"
            view.userLocation.text = self.users[index].location
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
        koloda.reloadData()
    }
    
    func koloda(_ koloda: KolodaView, didSelectCardAt index: Int) {
        performSegue(withIdentifier: "GoToProfile", sender: koloda)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToProfile" {
            if let destination = segue.destination as? CardFullscreenViewController {
                let indexPath = self.kolodaView.currentCardIndex
                destination.url = users[indexPath].imageURL!
            }
        }
    }
    
    func viewController(forStoryboardName: String) -> UIViewController {
        return UIStoryboard(name: forStoryboardName, bundle: nil).instantiateInitialViewController()!
    }
    
    func kolodaNumberOfCards(_ koloda: KolodaView) -> Int {
        return users.count
    }
    
    func kolodaSpeedThatCardShouldDrag(_ koloda: KolodaView) -> DragSpeed {
        return .fast
    }
    
    func koloda(_ koloda: KolodaView, draggedCardWithPercentage finishPercentage: CGFloat, in direction: SwipeResultDirection) {
        print("Card dragged: \(finishPercentage), \(direction)")
        
        if direction == .right {
            
        } else if direction == .left {
            if finishPercentage >= 50 {

            }
        }
    }
}
