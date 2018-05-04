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
import Alertift
import JGProgressHUD

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

class MatchViewController: UIViewController, KolodaViewDelegate, KolodaViewDataSource, FiltersDelegate, CardFullscreenDelegate {
    
    // MARK: - Variables
    
    var kolodaView = LezKolodaView()
    let userImage = UIImageView()
    var users: [User] = []
    var superview = UIView()
    let likeImageView = UIImageView()
    var jellyAnimator: JellyAnimator?
    var user: User?
    let hud = JGProgressHUD(style: .dark)
    var handle: AuthStateDidChangeListenerHandle?
    
    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if users.count < 1 {
            fetchPotentialMatches()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        try! Auth.auth().signOut()
        handle = Auth.auth().addStateDidChangeListener { auth, user in
            if let _ = user {
                self.navigationItem.title = "Match Room"
                let filterButton = UIButton(type: .custom)
                filterButton.setImage(UIImage(named: "Filter"), for: .normal)
                filterButton.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
                filterButton.addTarget(self, action: #selector(self.showFilters), for: .touchUpInside)
                let rightItem = UIBarButtonItem(customView: filterButton)
                self.navigationItem.setRightBarButtonItems([rightItem], animated: true)
                self.navigationController?.navigationBar.backgroundColor = .white
                self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
                self.navigationController?.navigationBar.shadowImage = UIImage()
                
                if let currentUser = Auth.auth().currentUser {
                    Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                        AnalyticsParameterItemID: "id-\(currentUser.uid)",
                        AnalyticsParameterItemName: "MatchViewController",
                        AnalyticsParameterContentType: "screen_view"
                    ])
                    self.startSpinner()
                    FirestoreManager.shared.fetchUser(uid: currentUser.uid).then { (user) in
                        self.user = user
                        if !user.isOnboarded {
                            let setupProfileViewController = SetupProfileViewController()
                            setupProfileViewController.name = user.name
                            setupProfileViewController.email = user.email
                            let navigationController = UINavigationController(rootViewController: setupProfileViewController)
                            self.present(navigationController, animated: false, completion: nil)
                        }
                        FirestoreManager.shared.fetchPotentialMatches(for: user).then({ (users) in
                            self.users = users
                            if self.users.isEmpty {
                                Alertift.alert(title: "Nothing to Show", message: "Change matching preferences.")
                                    .action(.default("Okay"))
                                    .show()
                            }
                            self.setupKoloda()
                            self.stopSpinner()
                        })
                    }
                }
                
            } else {
                // No User is signed in. Show user the login screen
                let registerViewController = RegisterViewController()
                let navigationController = UINavigationController(rootViewController: registerViewController)
                self.present(navigationController, animated: false, completion: nil)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    // MARK: - Methods
    fileprivate func startSpinner() {
        hud.textLabel.text = "Loading"
        hud.show(in: self.view)
    }
    
    fileprivate func fetchPotentialMatches() {
        print("Fetching new users")
        if let currentUser = Auth.auth().currentUser {
            Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                AnalyticsParameterItemID: "id-\(currentUser.uid)",
                AnalyticsParameterItemName: "MatchViewController",
                AnalyticsParameterContentType: "screen_view"
                ])
            self.startSpinner()
            FirestoreManager.shared.fetchUser(uid: currentUser.uid).then { (user) in
                self.user = user
                FirestoreManager.shared.fetchPotentialMatches(for: user).then({ (users) in
                    self.users = users
                    if self.users.isEmpty {
                        Alertift.alert(title: "Nothing to Show", message: "Change matching preferences.")
                            .action(.default("Okay"))
                            .show()
                    }
                    self.kolodaView.reloadData()
                    self.stopSpinner()
                })
            }
        }
    }
    
    fileprivate func stopSpinner() {
        hud.dismiss(animated: true)
    }
    
    fileprivate func setupKoloda() {
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
    
    fileprivate func playMatchAnimation() {
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
//        let nextViewController = FilterViewController()
//        let customBlurFadeInPresentation = JellyFadeInPresentation(dismissCurve: .easeInEaseOut,
//                                                                   presentationCurve: .easeInEaseOut,
//                                                                   backgroundStyle: .blur(effectStyle: .light))
//        self.jellyAnimator = JellyAnimator(presentation: customBlurFadeInPresentation)
//        self.jellyAnimator?.prepare(viewController: nextViewController)
//        present(nextViewController, animated: true, completion: nil)
        
        let filterViewController = FilterViewController()
        filterViewController.delegate = self
        let navigationController = UINavigationController(rootViewController: filterViewController)
        self.present(navigationController, animated: false, completion: nil)
    }
    
    func refreshKolodaData() {
        print("Reloading users")
        guard let currentUserUid = Auth.auth().currentUser?.uid else { return }
        FirestoreManager.shared.fetchUser(uid: currentUserUid).then { (user) in
            FirestoreManager.shared.fetchPotentialMatches(for: user).then({ (users) in
                self.users = users
                if self.users.isEmpty {
                    Alertift.alert(title: "Nothing to Show", message: "Change matching preferences.")
                        .action(.default("Okay"))
                        .show()
                }
                self.kolodaView.reloadData()
            })
        }
        
    }
    
    func dislikeUser() {
        kolodaView.swipe(.left)
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
            var previousLikes: [String] = []
            guard let user = user else { return }
            FirestoreManager.shared.fetchUser(uid: user.uid).then { (user) in
                previousLikes = user.likes!
                previousLikes.append(self.users[index].uid)
                let data = [
                    "likes": previousLikes
                ]
                FirestoreManager.shared.updateUser(uid: user.uid, data: data).then({ (success) in
                    if success {
                        FirestoreManager.shared.checkIfLikedUserIsMatch(currentUserUid: user.uid, likedUserUid: self.users[index].uid).then({ (success) in
                            if success {
                                var participants: [String] = []
                                participants.append(user.uid)
                                participants.append(self.users[index].uid)
                                let data: [String: Any] = [
                                    "created": FieldValue.serverTimestamp(),
                                    "participants": participants,
                                    "lastUpdated": FieldValue.serverTimestamp()
                                ]
                                FirestoreManager.shared.addEmptyChat(data: data, for: user.uid, herUid: self.users[index].uid).then({ (success) in
                                    if success {
                                        self.playMatchAnimation()
                                        self.showMatchModal()
                                    }
                                })
                            }
                        })
                    } else {
                        print("Error happened.")
                    }
                })
            }
        } else if direction == .left {
            var previousDislikes: [String] = []
            let currentUser = Auth.auth().currentUser!.uid
            FirestoreManager.shared.fetchUser(uid: currentUser).then { (user) in
                previousDislikes = user.dislikes!
                previousDislikes.append(self.users[index].uid)
                let data = [
                    "dislikes": previousDislikes
                ]
                FirestoreManager.shared.updateUser(uid: currentUser, data: data).then({ (success) in
                    if success {
                        print("Dislike added")
                    } else {
                        print("Error happened.")
                    }
                })
            }
        }
    }
    
    func kolodaDidRunOutOfCards(_ koloda: KolodaView) {
        fetchPotentialMatches()
    }
    
    func koloda(_ koloda: KolodaView, didSelectCardAt index: Int) {
        let nextViewController = CardFullscreenViewController()
        nextViewController.delegate = self
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
