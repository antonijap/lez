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
import StoreKit
import SwiftyStoreKit

class MatchViewController: UIViewController, KolodaViewDelegate, KolodaViewDataSource, MatchViewControllerDelegate, GetPremiumViewControllerDelegate {
    
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
    var timerLabel = UILabel()
    var seconds = 5//86400
    var timer = Timer()
    var timerBuyButton = CustomButton()
    var timerDescriptionLabel = UILabel()
    let timerBoxView = UIView()
    let noCardsBoxView = UIView()
    let noCardsButton = CustomButton()
    let noCardsLabel = UILabel()

    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkIfTimerNeedsToBeUpdated()
        
        SwiftyStoreKit.retrieveProductsInfo(["com.antonijapek.Lez.premium"]) { result in
            if let product = result.retrievedProducts.first {
                let priceString = product.localizedPrice!
                print("Product: \(product.localizedDescription), price: \(priceString)")
            }
            else if let invalidProductId = result.invalidProductIDs.first {
                print("Invalid product identifier: \(invalidProductId)")
            }
            else {
                print("Error: \(String(describing: result.error))")
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        try! Auth.auth().signOut()
        NotificationCenter.default.addObserver(self, selector:#selector(self.checkIfTimerNeedsToBeUpdated), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        handle = Auth.auth().addStateDidChangeListener { auth, user in
            if let currentUser = user {
                print("User detected")
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
                        self.setupKoloda()
                        self.setupTimer()
                        self.showTimer()
                        self.setupNoCards()
                        print(users.count)
                        if users.count <= 0 {
                            self.showNoCards()
                        }
                    })
                }
            } else {
                // No User is signed in. Show user the login screen
                let registerViewController = RegisterViewController()
                let navigationController = UINavigationController(rootViewController: registerViewController)
                self.present(navigationController, animated: false, completion: nil)
            }
        }
    }
    
    // MARK: - Methods
    fileprivate func setupTimer() {
        view.insertSubview(timerBoxView, aboveSubview: kolodaView)
        timerBoxView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        timerBoxView.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        
        timerBoxView.addSubview(timerLabel)
        timerLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(view.frame.height / 2.6)
            make.left.equalToSuperview().offset(40)
            make.right.equalToSuperview().inset(40)
        }
        timerLabel.text = "Timer"
        timerLabel.font = UIFont.systemFont(ofSize: 28, weight: .heavy)
        timerLabel.textAlignment = .center
        
        timerBoxView.addSubview(timerDescriptionLabel)
        timerDescriptionLabel.snp.makeConstraints { (make) in
            make.top.equalTo(timerLabel.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(40)
            make.right.equalToSuperview().inset(40)
        }
        timerDescriptionLabel.text = "No more likes, get Premium or wait for 24 hours."
        timerDescriptionLabel.font = UIFont.systemFont(ofSize: 21, weight: .medium)
        timerDescriptionLabel.numberOfLines = 2
        timerDescriptionLabel.textAlignment = .center
        
        timerBoxView.addSubview(timerBuyButton)
        timerBuyButton.snp.makeConstraints { (make) in
            make.top.equalTo(timerDescriptionLabel.snp.bottom).offset(40)
            make.left.equalToSuperview().offset(40)
            make.right.equalToSuperview().inset(40)
            make.height.equalTo(48)
        }
        timerBuyButton.setTitle("Unlock Now", for: .normal)
        timerBuyButton.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        let buttonTap = UITapGestureRecognizer(target: self, action: #selector(self.buyTapped(_:)))
        timerBuyButton.addGestureRecognizer(buttonTap)
        hideTimer()
    }
    
    fileprivate func hideTimer() {
        timer.invalidate()
        timerBoxView.isHidden = true
        timerLabel.isHidden = true
        timerDescriptionLabel.isHidden = true
        timerBuyButton.isHidden = true
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    
    func showTimer() {
        timerBoxView.isHidden = false
        timerLabel.isHidden = false
        timerDescriptionLabel.isHidden = false
        timerBuyButton.isHidden = false
        runTimer()
        updateTimer()
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    @objc func buyTapped(_ sender: UIButton) {
        let nextViewController = GetPremiumViewController()
        let customBlurFadeInPresentation = JellyFadeInPresentation(dismissCurve: .easeInEaseOut,
                                                                   presentationCurve: .easeInEaseOut,
                                                                   backgroundStyle: .blur(effectStyle: .light))
        self.jellyAnimator = JellyAnimator(presentation: customBlurFadeInPresentation)
        self.jellyAnimator?.prepare(viewController: nextViewController)
        self.present(nextViewController, animated: true, completion: nil)
    }
    
    @objc fileprivate func checkIfTimerNeedsToBeUpdated() {
        runTimer()
    }
    
    fileprivate func runTimer() {
        timer.invalidate()
        guard let user = user else { return }
        if let cooldownTime = user.cooldownTime {
            let timeUntilKolodaUnlocks = cooldownTime.add(components: 24.hours)
            let differenceBetweenNowAndTimeUntilKolodaUnlocks = timeUntilKolodaUnlocks.timeIntervalSinceNow
            self.seconds = Int(differenceBetweenNowAndTimeUntilKolodaUnlocks)
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(self.updateTimer)), userInfo: nil, repeats: true)
        } else {
            self.hideTimer()
        }
    }
    
    // Ovo ne diraj
    @objc func updateTimer() {
        if (seconds - 1) == 0 {
            guard let user = user else { return }
            let data: [String: Any] = [
                "matchesLeft": 5,
                "cooldownTime": ""
            ]
            FirestoreManager.shared.updateUser(uid: user.uid, data: data).then { (user) in
                self.hideTimer()
                if self.kolodaView.countOfCards == 0 {
                    self.refreshKolodaData()
                }
            }
        } else {
            seconds -= 1
            timerLabel.text = timeString(time: TimeInterval(seconds))
        }
        
    }
    
    fileprivate func timeString(time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
    }
    
    fileprivate func setupNoCards() {
        view.insertSubview(noCardsBoxView, aboveSubview: kolodaView)
        noCardsBoxView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        noCardsBoxView.addSubview(noCardsLabel)
        noCardsLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(view.frame.height / 2.5)
            make.left.equalToSuperview().offset(40)
            make.right.equalToSuperview().inset(40)
        }
        noCardsLabel.text = "Deck empty, let's try to find more matches. Hit refresh."
        noCardsLabel.font = UIFont.systemFont(ofSize: 21, weight: .medium)
        noCardsLabel.numberOfLines = 2
        noCardsLabel.textAlignment = .center

        noCardsBoxView.addSubview(noCardsButton)
        noCardsButton.snp.makeConstraints { (make) in
            make.top.equalTo(noCardsLabel.snp.bottom).offset(40)
            make.left.equalToSuperview().offset(40)
            make.right.equalToSuperview().inset(40)
            make.height.equalTo(48)
        }
        noCardsButton.setTitle("Refresh Deck", for: .normal)
        noCardsButton.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        let buttonTap = UITapGestureRecognizer(target: self, action: #selector(self.refreshKolodaData))
        noCardsButton.addGestureRecognizer(buttonTap)
        hideNoCards()
    }
    
    fileprivate func showNoCards() {
        noCardsBoxView.isHidden = false
    }
    
    fileprivate func hideNoCards() {
        noCardsBoxView.isHidden = true
    }
    
    fileprivate func startSpinner() {
        hud.textLabel.text = "Loading"
        hud.show(in: self.view)
        hud.interactionType = .blockAllTouches
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
        
        if kolodaView.countOfCards == 0 {
            setupTimer()
        }
    }
    
    fileprivate func playMatchAnimation(completion: @escaping () -> Void) {
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
            completion()
        })
    }
    
    @objc func showFilters() {
        let filterViewController = FilterViewController()
        filterViewController.delegate = self
        let navigationController = UINavigationController(rootViewController: filterViewController)
        self.present(navigationController, animated: false, completion: nil)
    }
    
    @objc func refreshKolodaData() {
        guard let currentUser = Auth.auth().currentUser else { return }
        FirestoreManager.shared.fetchUser(uid: currentUser.uid).then { (user) in
            self.user = user
            FirestoreManager.shared.fetchPotentialMatches(for: user).then({ (users) in
                self.users = users
                if self.users.isEmpty {
                    Alertift.alert(title: "Nothing to Show", message: "Change matching preferences.")
                        .action(.default("Okay"), handler: { (_, _, _) in
                            self.showNoCards()
                        })
                        .show()
                }
                self.hideNoCards()
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
            guard let user = user else { return}
            FirestoreManager.shared.checkIfUserHasAvailableMatches(for: user.uid).then({ (hasMatches) in
                if hasMatches {
                    FirestoreManager.shared.fetchUser(uid: user.uid).then { (user) in
                        if (user.matchesLeft - 1) == 0 {
                            var previousLikes: [String] = []
                            previousLikes = user.likes!
                            previousLikes.append(self.users[index].uid)
                            let data: [String: Any] = [
                                "matchesLeft": user.matchesLeft - 1,
                                "likes": previousLikes,
                                "cooldownTime": Date().toString(dateFormat: "yyyy-MM-dd HH:mm:ss")
                            ]
                            FirestoreManager.shared.updateUser(uid: user.uid, data: data).then({ (success) in
                                FirestoreManager.shared.checkIfLikedUserIsMatch(currentUserUid: user.uid, likedUserUid: self.users[index].uid).then({ (success) in
                                    if success {
                                        var participants: [String] = []
                                        participants.append(user.uid)
                                        participants.append(self.users[index].uid)
                                        let data: [String: Any] = [
                                            "created": FieldValue.serverTimestamp(),
                                            "participants": participants,
                                            "lastUpdated": FieldValue.serverTimestamp(),
                                            ]
                                        FirestoreManager.shared.addEmptyChat(data: data, for: user.uid, herUid: self.users[index].uid).then({ (success) in
                                            if success {
                                                self.playMatchAnimation {
                                                    self.showMatchModal()
                                                }
                                            }
                                        })
                                    }
                                })
                            })
                        } else {
                            var previousLikes: [String] = []
                            previousLikes = user.likes!
                            previousLikes.append(self.users[index].uid)
                            let data: [String: Any] = [
                                "matchesLeft": user.matchesLeft - 1,
                                "likes": previousLikes
                            ]
                            
                            FirestoreManager.shared.updateUser(uid: user.uid, data: data).then({ (success) in
                                FirestoreManager.shared.checkIfLikedUserIsMatch(currentUserUid: user.uid, likedUserUid: self.users[index].uid).then({ (success) in
                                    if success {
                                        var participants: [String] = []
                                        participants.append(user.uid)
                                        participants.append(self.users[index].uid)
                                        let data: [String: Any] = [
                                            "created": FieldValue.serverTimestamp(),
                                            "participants": participants,
                                            "lastUpdated": FieldValue.serverTimestamp(),
                                            ]
                                        FirestoreManager.shared.addEmptyChat(data: data, for: user.uid, herUid: self.users[index].uid).then({ (success) in
                                            if success {
                                                self.playMatchAnimation {
                                                    self.showMatchModal()
                                                }
                                            }
                                        })
                                    }
                                })
                            })
                        }
                    }
                    if self.kolodaView.isRunOutOfCards {
                        self.showNoCards()
                    } else {
                        self.hideNoCards()
                    }
                } else {
                    self.kolodaView.revertAction()
                    let nextViewController = GetPremiumViewController()
                    nextViewController.delegate = self
                    let customBlurFadeInPresentation = JellyFadeInPresentation(dismissCurve: .easeInEaseOut,
                                                                               presentationCurve: .easeInEaseOut,
                                                                               backgroundStyle: .blur(effectStyle: .light))
                    self.jellyAnimator = JellyAnimator(presentation: customBlurFadeInPresentation)
                    self.jellyAnimator?.prepare(viewController: nextViewController)
                    self.present(nextViewController, animated: true, completion: nil)
                }
            })
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
        showNoCards()
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
