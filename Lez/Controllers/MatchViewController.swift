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
import Lottie
import Jelly
import Firebase
import FBSDKLoginKit

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
    var jellyAnimator: JellyAnimator?
    
    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Check if user is signed-in
        Auth.auth().addStateDidChangeListener { auth, user in
            if let _ = user {
//               let isOnboarded = DefaultsManager.sharedInstance.isCurrentUserOnboarded()
//
//                if !isOnboarded {
//                    let setupProfileViewController = SetupProfileViewController()
//                    setupProfileViewController.name = user?.displayName!
//                    setupProfileViewController.email = user?.email!
//                    let navigationController = UINavigationController(rootViewController: setupProfileViewController)
//                    self.present(navigationController, animated: false, completion: nil)
//                }
                
                
            } else {
                // No User is signed in. Show user the login screen
                let registerViewController = RegisterViewController()
                let navigationController = UINavigationController(rootViewController: registerViewController)
                self.present(navigationController, animated: false, completion: nil)
            }
        }
    }
    
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
        
        let ageRange = AgeRange(from: 21, to: 32)
        let details = Details(about: "Hello this is about.", dealBreakers: "This is my dealbreaker.", diet: .vegan)
        let preferences = Preferences(ageRange: ageRange, lookingFor: [LookingFor.friendship.rawValue, LookingFor.relationship.rawValue])
        let user = User(uid: "e4sds23492", name: "Somename", email: "some@email.com", age: 32, location: Location(city: "Zagreb", country: "Croatia"), preferences: preferences, details: details)
        user.images = ["https://picsum.photos/200/300/?random", "https://picsum.photos/200/300/?random", "https://picsum.photos/200/300/?random"]
        users.append(user)
        users.append(user)
        users.append(user)
        users.append(user)
        setupKoloda()
    }
    
    // MARK: - Methods
    func setupKoloda() {
        kolodaView.dataSource = self
        kolodaView.delegate = self
        kolodaView.countOfVisibleCards = 3
        view.addSubview(kolodaView)
        kolodaView.snp.setLabel("KOLODA_VIEW")
        kolodaView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin).inset(24)
            make.width.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8))
            make.centerX.equalToSuperview()
        }
    }
    
    func playMatchAnimation() {
        kolodaView.layer.opacity = 0.2
        let animationView = LOTAnimationView(name: "MatchAnimation")
        animationView.contentMode = .scaleAspectFit
        view.addSubview(animationView)
        animationView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.size.equalToSuperview()
        }
        animationView.play()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
            animationView.stop()
            animationView.isHidden = true
            self.kolodaView.layer.opacity = 1.0
        })
    }
    
    @objc func showFilters() {
        let nextViewController = FilterViewController()
        let customBlurFadeInPresentation = JellyFadeInPresentation(dismissCurve: .easeInEaseOut,
                                                                   presentationCurve: .easeInEaseOut,
                                                                   backgroundStyle: .blur(effectStyle: .light))
        self.jellyAnimator = JellyAnimator(presentation: customBlurFadeInPresentation)
        self.jellyAnimator?.prepare(viewController: nextViewController)
        present(nextViewController, animated: true, completion: nil)
    }
}

extension MatchViewController {
    func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {
        let view = LezKolodaView()
        view.imageView.moa.url = users[index].images!.first
        view.imageView.moa.onSuccess = { image in
            view.locationLabel.text = self.users[index].location.city
            view.nameAndAgeLabel.text = "\(self.users[index].name), \(self.users[index].age)"
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
    
    func koloda(_ koloda: KolodaView, didSwipeCardAt index: Int, in direction: SwipeResultDirection) {
        if direction == .right {
            playMatchAnimation()
        }
    }
    
    func kolodaDidRunOutOfCards(_ koloda: KolodaView) {
        kolodaView.reloadData()
    }
    
    func koloda(_ koloda: KolodaView, didSelectCardAt index: Int) {
        let nextViewController = CardFullscreenViewController()
//        self.navigationController?.push(nextViewController)
        nextViewController.user = self.users[index]
        let customBlurFadeInPresentation = JellyFadeInPresentation(dismissCurve: .easeInEaseOut,
                                                                   presentationCurve: .easeInEaseOut,
                                                                   backgroundStyle: .blur(effectStyle: .light))
        self.jellyAnimator = JellyAnimator(presentation: customBlurFadeInPresentation)
        self.jellyAnimator?.prepare(viewController: nextViewController)
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
