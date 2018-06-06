//
//  MatchViewController2.swift
//  Lez
//
//  Created by Antonija Pek on 10/05/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import UIKit
import SnapKit
import Jelly
import Firebase
import Jelly
import Promises
import Alamofire
import SwiftDate
import SDWebImage
import Spring
import JGProgressHUD
import SwiftyJSON
import Alertift
import PusherSwift
import Toast_Swift
import SwiftyStoreKit

class MatchViewController2: UIViewController, MatchViewControllerDelegate, PusherDelegate {
    
    // MARK: - Properties
    private let tableView = UITableView()
    private let likesCounterWidgetView = UIView()
    private let likesCounterWidgetImageView = UIImageView()
    private let likesCounterWidgetLabel = UILabel()
    private let matchYourImageView = SpringImageView()
    private let matchHerImageView = SpringImageView()
    private let matchLabel = UILabel()
    private let matchCTA = CustomButton()
    private let matchCloseButton = UIButton()
    private let matchView = SpringView()
    private let matchOverlayView = SpringView()
    private let matchDescriptionLabel = SpringLabel()
    private let matchSubtitle = SpringLabel()
    private let noUsersBackground = UIImageView()
    private let noUsersTitle = UILabel()
    private let noUsersDescription = UILabel()
    private let noUsersCTA = CustomButton()
    private let noUsersRefreshButton = SpringButton()
    private let refreshControl = UIRefreshControl()
    private var users: [User] = []
    private var user: User?
    private var jellyAnimator: JellyAnimator?
    private var seconds = 86400
    private var handle: AuthStateDidChangeListenerHandle?
    private let hud = JGProgressHUD(style: .dark)
    private var pusher: Pusher!
    private var options: PusherClientOptions!
    private var canLike: Bool!
    private var likesLeft: Int!
    private var timer = Timer()
    
    // MARK: - Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear")
        if let currentUser = Auth.auth().currentUser {
            FirestoreManager.shared.fetchUser(uid: currentUser.uid).then { (user) in
                self.user = user
                self.options = PusherClientOptions(host: .cluster("eu"))
                self.pusher = Pusher(key: "b5bd116d3da803ac6d12", options: self.options)
                self.pusher.connection.delegate = self
                self.pusher.connect()

                let channel = self.pusher.subscribe(currentUser.uid)

                let _ = channel.bind(eventName: Events.newMessage.rawValue, callback: { (data: Any?) -> Void in
                    if let data = data as? [String : AnyObject] {
                        if let message = data["message"] as? String {
                            self.view.makeToast(message, duration: 2.0, position: .bottom)
                            let increment = DefaultsManager.shared.fetchNumber() + 1
                            if let tabItems = self.tabBarController?.tabBar.items as NSArray? {
                                let tabItem = tabItems[1] as! UITabBarItem
                                tabItem.badgeValue = String(increment)
                                DefaultsManager.shared.save(number: increment)
                            }
                        }
                    }
                })
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let _ = Auth.auth().currentUser {
            if let _ = user {
                pusher.disconnect()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ViewDidLoad")
        setupTableView()
        setupNavigationBar()
        setupMatchView()
        setupNoUsersState()
        setupLikesWidget()
        
        DefaultsManager.shared.save(number: 0)
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshTableView), name: Notification.Name("RefreshTableView"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateAfterAppComesToForeground), name:
            NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        handle = Auth.auth().addStateDidChangeListener { auth, user in
            if let user = user {
                Firestore.firestore().collection("users").document(user.uid).getDocument { documentSnapshot, error in
                    guard let document = documentSnapshot else {
                        print("Error fetching document: \(error!)")
                        return
                    }
                    guard let _ = document.data() else {
                        self.presentRegisterViewController()
                        return
                    }
                    
                    FirestoreManager.shared.parseFirebaseUser(document: document).then({ (user) in
                        guard let me = user else { return }
                        self.fetchUsers(for: me.uid)
                        PurchaseManager.shared.checkIfSubscribed(user: me, ifManuallyPromoted: me.isManuallyPromoted)
                        if me.isOnboarded == false {
                            self.presentRegisterViewController()
                        }
                    })
                }
            } else {
                self.presentRegisterViewController()
            }
        }
    }
    
    // MARK: - Methods
    func failedToSubscribeToChannel(name: String, response: URLResponse?, data: String?, error: NSError?) {
        print("FAILED to subscribe \(name), \(error.debugDescription)")
    }
    
    @objc func updateAfterAppComesToForeground() {
        print("I have come to foreground.")
        guard let currentUser = Auth.auth().currentUser else { return }
        FirestoreManager.shared.fetchUser(uid: currentUser.uid).then { (user) in
            guard let cooldownTime = user.cooldownTime else { return }
            self.runTimer(cooldownTime: cooldownTime)
        }
    }
    
    private func startSpinner() {
        hud.textLabel.text = "Please wait..."
        hud.vibrancyEnabled = true
        hud.interactionType = .blockAllTouches
        hud.show(in: view)
    }
    
    private func stopSpinner() {
        hud.dismiss(animated: true)
    }
    
    private func presentRegisterViewController() {
        let registerViewController = RegisterViewController()
        let navigationController = UINavigationController(rootViewController: registerViewController)
        self.present(navigationController, animated: false, completion: nil)
    }
    
    @objc func refreshTableView() {
        guard let user = user else {
            if let currentUser = Auth.auth().currentUser {
                FirestoreManager.shared.fetchUser(uid: currentUser.uid).then { (user) in
                    self.user = user
                    self.fetchUsers(for: user.uid)
                }
            }
            return
        }
        fetchUsers(for: user.uid)
    }
    
    private func setupNoUsersState() {
        view.addSubview(noUsersBackground)
        noUsersBackground.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
            make.right.left.equalToSuperview()
        }
        noUsersBackground.image = UIImage(named: "No_Users_Background")
        noUsersBackground.contentMode = .scaleAspectFill
        noUsersBackground.clipsToBounds = true
        
        view.addSubview(noUsersTitle)
        noUsersTitle.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(view.frame.height / 3.0)
            make.centerX.equalToSuperview()
        }
        noUsersTitle.text = "Bummer"
        noUsersTitle.font = UIFont.systemFont(ofSize: 28, weight: .heavy)
        
        view.addSubview(noUsersDescription)
        noUsersDescription.snp.makeConstraints { (make) in
            make.top.equalTo(noUsersTitle.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(32)
            make.right.equalToSuperview().inset(32)
        }
        noUsersDescription.text = "No lesbians with your criteria. Try changing preferences."
        noUsersDescription.numberOfLines = 2
        noUsersDescription.font = UIFont.systemFont(ofSize: 21, weight: .medium)
        noUsersDescription.textAlignment = .center
        
        view.addSubview(noUsersCTA)
        noUsersCTA.snp.makeConstraints { (make) in
            make.top.equalTo(noUsersDescription.snp.bottom).offset(32)
            make.left.equalToSuperview().offset(48)
            make.right.equalToSuperview().inset(48)
            make.height.equalTo(48)
        }
        noUsersCTA.setTitle("Spread Word", for: .normal)
        noUsersCTA.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        let buttonTap = UITapGestureRecognizer(target: self, action: #selector(self.shareWebsite))
        noUsersCTA.addGestureRecognizer(buttonTap)
        
        view.addSubview(noUsersRefreshButton)
        noUsersRefreshButton.snp.makeConstraints { (make) in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin).inset(32)
            make.centerX.equalToSuperview()
        }
        noUsersRefreshButton.setTitle("Try refresh?", for: .normal)
        noUsersRefreshButton.addTarget(self, action: #selector(self.refreshTableView), for: .touchUpInside)
        noUsersRefreshButton.setTitleColor(.gray, for: .normal)
        noUsersRefreshButton.setTitleColor(UIColor.gray.withAlphaComponent(0.5), for: .highlighted)
        
        hideEmptyState()
    }
    
    private func hideEmptyState() {
        noUsersBackground.isHidden = true
        noUsersTitle.isHidden = true
        noUsersDescription.isHidden = true
        noUsersCTA.isHidden = true
        noUsersRefreshButton.isHidden = true
    }
    
    private func showEmptyState() {
        noUsersBackground.isHidden = false
        noUsersTitle.isHidden = false
        noUsersDescription.isHidden = false
        noUsersCTA.isHidden = false
        noUsersRefreshButton.isHidden = false
    }
    
    @objc private func shareWebsite() {
        let web = NSURL(string: "http://getlez.com")
        AnalyticsManager.shared.logEvent(name: AnalyticsEvents.userSharedURL, user: user!)
        web.share()
    }
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.right.left.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
        }
        tableView.register(MatchCell.self, forCellReuseIdentifier: "MatchCell")
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(self.refreshTableView), for: .valueChanged)
    }
    
    private func setupNavigationBar() {
        navigationItem.title = "Match Room"
        navigationController?.navigationBar.backgroundColor = .white
        navigationController?.navigationBar.setBackgroundImage(UIImage(named: "White"), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layer.masksToBounds = false
        navigationController?.navigationBar.layer.shadowColor = UIColor(red:0.90, green:0.90, blue:0.90, alpha:1.00).cgColor
        navigationController?.navigationBar.layer.shadowOpacity = 0.8
        navigationController?.navigationBar.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        navigationController?.navigationBar.layer.shadowRadius = 4
        let filterButton = UIButton(type: .custom)
        filterButton.setImage(UIImage(named: "Filter"), for: .normal)
        filterButton.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        filterButton.addTarget(self, action: #selector(self.showFilters), for: .touchUpInside)
        let rightItem = UIBarButtonItem(customView: filterButton)
        navigationItem.setRightBarButtonItems([rightItem], animated: true)
    }
    
    private func setupLikesWidget() {
        view.addSubview(likesCounterWidgetView)
        likesCounterWidgetView.snp.makeConstraints { (make) in
            make.height.equalTo(32)
            make.left.equalToSuperview().offset(16)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin).inset(16)
        }
        likesCounterWidgetView.layer.cornerRadius = 16
        likesCounterWidgetView.clipsToBounds = false
        likesCounterWidgetView.backgroundColor = .white
        likesCounterWidgetView.dropShadow()
        
        likesCounterWidgetView.addSubview(likesCounterWidgetImageView)
        likesCounterWidgetImageView.snp.makeConstraints { (make) in
            make.height.width.equalTo(20)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(8)
        }
        likesCounterWidgetImageView.image = UIImage(named: "Like")
        
        likesCounterWidgetView.addSubview(likesCounterWidgetLabel)
        likesCounterWidgetLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(likesCounterWidgetImageView.snp.right).offset(4)
            make.right.equalToSuperview().inset(12)
        }
      
        likesCounterWidgetView.layoutIfNeeded()
    }
    
    func showLikesWidget() {
        likesCounterWidgetView.isHidden = false
    }
    
    func hideLikesWidget() {
        likesCounterWidgetView.isHidden = true
    }
    
    private func runLikesWidget() {
        guard let user = Auth.auth().currentUser else { return }
        Firestore.firestore().collection("users").document(user.uid).addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            FirestoreManager.shared.parseFirebaseUser(document: document).then({ (user) in
                guard let user = user else { return }
                print("User downloaded: \(String(describing: user))")
                self.user = user
                if user.isPremium {
                    print("BUREK Will adjust widget to show unlimited")
                    self.canLike = true
                    self.likesLeft = user.likesLeft
                    self.likesCounterWidgetLabel.text = "Unlimited"
                    self.likesCounterWidgetImageView.image = UIImage(named: "Like")
                } else {
                    if user.likesLeft <= 0 {
                        // Show countdown
                        print("BUREK User has to wait")
                        self.canLike = false
                        self.likesLeft = user.likesLeft
                        guard let cooldownTime = user.cooldownTime else { return }
                        self.runTimer(cooldownTime: cooldownTime)
                        self.likesCounterWidgetImageView.image = UIImage(named: "Like_Disabled")
                    } else {
                        // Show likesLeft
                        print("BUREK User has more likes...")
                        self.canLike = true
                        self.likesLeft = user.likesLeft
                        self.likesCounterWidgetLabel.text = "\(self.likesLeft!)"
                        self.likesCounterWidgetImageView.image = UIImage(named: "Like")
                    }
                }
            })
        }
    }
    
    private func setupMatchView() {
        UIApplication.shared.keyWindow?.addSubview(matchOverlayView)
        matchOverlayView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        matchOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        UIApplication.shared.keyWindow?.addSubview(matchView)
        matchView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(32)
            make.right.equalToSuperview().inset(32)
            make.center.equalToSuperview()
        }
        matchView.backgroundColor = .white
        matchView.layer.cornerRadius = 8
        matchView.dropShadow()
        
        matchView.addSubview(matchYourImageView)
        matchYourImageView.snp.makeConstraints { (make) in
            make.height.width.equalTo(48)
            make.centerX.equalToSuperview().inset(10)
            make.top.equalToSuperview().offset(40)
        }
        matchYourImageView.backgroundColor = UIColor(red:0.77, green:0.77, blue:0.77, alpha:1.00)
        matchYourImageView.layer.cornerRadius = 48 / 2
        matchYourImageView.clipsToBounds = true
        
        matchView.addSubview(matchHerImageView)
        matchHerImageView.snp.makeConstraints { (make) in
            make.height.width.equalTo(48)
            make.centerX.equalToSuperview().inset(-10)
            make.top.equalTo(matchYourImageView.snp.top)
        }
        matchHerImageView.backgroundColor = UIColor(red:0.69, green:0.69, blue:0.69, alpha:1.00)
        matchHerImageView.layer.cornerRadius = 48 / 2
        matchHerImageView.clipsToBounds = true
        
        matchView.addSubview(matchLabel)
        matchLabel.snp.makeConstraints { (make) in
            make.top.equalTo(matchHerImageView.snp.bottom).offset(32)
            make.centerX.equalToSuperview()
        }
        matchLabel.text = "Match"
        matchLabel.font = UIFont.systemFont(ofSize: 28, weight: .heavy)
        
        matchView.addSubview(matchSubtitle)
        matchSubtitle.snp.makeConstraints { (make) in
            make.top.equalTo(matchLabel.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().inset(24)
            make.right.equalToSuperview().offset(-24)
        }
        matchSubtitle.font = UIFont.systemFont(ofSize: 21, weight: .regular)
        matchSubtitle.numberOfLines = 2
        matchSubtitle.textAlignment = .center
        
        matchView.addSubview(matchCTA)
        matchCTA.snp.makeConstraints { (make) in
            make.top.equalTo(matchSubtitle.snp.bottom).offset(32)
            make.left.equalToSuperview().offset(32)
            make.right.equalToSuperview().inset(32)
            make.height.equalTo(44)
            make.bottom.equalToSuperview().inset(40)
        }
        matchCTA.setTitle("Go to Chat", for: .normal)
        matchCTA.addTarget(self, action: #selector(self.goToChat), for: .touchUpInside)
        
        matchView.addSubview(matchCloseButton)
        matchCloseButton.snp.makeConstraints { (make) in
            make.width.equalTo(32)
            make.height.equalTo(32)
            make.right.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(16)
        }
        matchCloseButton.setImage(UIImage(named: "Close"), for: .normal)
        matchCloseButton.addTarget(self, action: #selector(self.closeButtonTapped(_:)), for:.touchUpInside)
        
        matchView.alpha = 0
        matchOverlayView.alpha = 0
    }
    
    @objc func closeButtonTapped(_ sender: UIButton) {
        hideMatch()
    }
    
    @objc func goToChat() {
        hideMatch()
        tabBarController?.selectedIndex = 1
    }
    
    private func hideMatch() {
        matchOverlayView.animation = "fadeOut"
        matchOverlayView.animate()
        matchView.animation = "fall"
        matchView.animate()
    }
    
    private func showMatch() {
        matchOverlayView.animation = "fadeIn"
        matchOverlayView.animate()
        matchView.animation = "pop"
        matchView.duration = 1
        matchView.curve = "spring"
        matchView.velocity = 20
        matchView.animate()
    }
    
    private func addImagesToMatch(myUrl: String, herUrl: String) {
        matchYourImageView.sd_setImage(with: URL(string: myUrl), placeholderImage: UIImage(named: "Placeholder_Image"))
        matchHerImageView.sd_setImage(with: URL(string: herUrl), placeholderImage: UIImage(named: "Placeholder_Image"))
    }
    
    @objc func fetchUsers(for uid: String) {
        startSpinner()
        runLikesWidget()
        refreshControl.endRefreshing()
        FirestoreManager.shared.fetchUser(uid: uid).then { (user) in
            self.user = user
            FirestoreManager.shared.fetchPotentialMatches(for: user).then({ (users) in
                self.users = users
                if users.count > 0 {
                    self.stopSpinner()
                    self.showLikesWidget()
                    self.hideEmptyState()
                    self.tableView.reloadData()
                } else {
                    self.stopSpinner()
                    self.hideLikesWidget()
                    self.showEmptyState()
                }
            })
        }
    }
    
    @objc private func runTimer(cooldownTime: Date) {
        timer.invalidate()
        // Adjust cooldown time
        let timeUntilNewLikesUnlock = cooldownTime.add(components: 10.minutes)
        let differenceBetweenNowAndTimeUntilNewLikesUnlock = timeUntilNewLikesUnlock.timeIntervalSinceNow
        print("BUREK Difference is \(differenceBetweenNowAndTimeUntilNewLikesUnlock)")
        seconds = Int(differenceBetweenNowAndTimeUntilNewLikesUnlock)
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(self.updateTimer)), userInfo: nil, repeats: true)
    }
    
    // Ovo ne diraj
    @objc func updateTimer() {
        if (seconds - 1) <= 0 {
            timer.invalidate()
            guard let user = user else { return }
            let data: [String: Any] = [
                "likesLeft": 5,
                "cooldownTime": ""
            ]
            FirestoreManager.shared.updateUser(uid: user.uid, data: data).then { (user) in
                print("Counter reached 0, user refreshed")
            }
        } else {
            seconds -= 1
            self.likesCounterWidgetLabel.text = timeString(time: TimeInterval(seconds))
        }
    }

    @objc func likeTouchUpInside(_ sender: MatchCell) {
        startSpinner()
        let cell = tableView.cellForRow(at: IndexPath(row: sender.tag, section: 0)) as! MatchCell
        cell.likeButton.transform = CGAffineTransform(scaleX: -1, y: 1)
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            cell.likeButton.transform = CGAffineTransform(scaleX: 1,y: 1)
            guard let user = self.user else {
                return
            }
            // Faster Liking Start
            if self.canLike {
                // Then like
                // Add like to Firestore
                let likesLeft = self.likesLeft
                var data: [String: Any] = [:]
                let her = self.users[sender.tag]
                
                var likes = user.likes!
                likes.append(her.uid)
                
                if user.isPremium {
                    data = ["likes": likes]
                } else {
                    if (likesLeft! - 1) == 0 {
                        data = ["likes": likes, "likesLeft": likesLeft! - 1, "cooldownTime": Date().string(custom: "yyyy-MM-dd HH:mm:ss")]
                    } else {
                        print("Will reduce one. Likes left: \(likesLeft! - 1)")
                        data = ["likes": likes, "likesLeft": likesLeft! - 1]
                    }
                }
                
                Firestore.firestore().collection("users").document(user.uid).updateData(data) { err in
                    if let err = err {
                        print("Error updating document: \(err)")
                    } else {
                        print("Document successfully updated")
                    }
                }
                // Now modify user in local model
                user.likes?.append(her.uid)
                
                // Reload table
                UIView.performWithoutAnimation {
                    self.tableView.reloadRows(at: [IndexPath(row: sender.tag, section: 0)], with: .top)
                }
                self.stopSpinner()
                Firestore.firestore().collection("users").document(her.uid).getDocument { documentSnapshot, error in
                    guard let document = documentSnapshot else {
                        print("Error fetching document: \(error!)")
                        return
                    }
                    guard let data = document.data() else { return }
                    guard let likes = data["likes"] as? [String] else {
                        print("Problem with parsing likes.")
                        return
                    }
                    if likes.contains(user.uid) {
                        self.addImagesToMatch(myUrl: user.images.first!.url, herUrl: her.images.first!.url)
                        self.matchSubtitle.text = "You and \(her.name) liked each other."
                        let data: [String: Any] = [
                            "created": Date().toString(dateFormat: "yyyy-MM-dd HH:mm:ss"),
                            "participants": [
                                user.uid: true,
                                self.users[sender.tag].uid: true
                            ],
                            "lastUpdated": Date().toString(dateFormat: "yyyy-MM-dd HH:mm:ss"),
                            "isDisabled": false
                        ]
                        FirestoreManager.shared.addEmptyChat(data: data, for: user.uid, herUid: self.users[sender.tag].uid).then({ (ref) in
                            self.showMatch()
                            AnalyticsManager.shared.logEvent(name: AnalyticsEvents.matchHappened, user: user)
                            let parameters: Parameters = ["uid": "\(self.users[sender.tag].uid)"]
                            Alamofire.request("https://us-central1-lesbian-dating-app.cloudfunctions.net/sendPushNotification", method: .post, parameters: parameters, encoding: URLEncoding.default)
                            let parameters2: Parameters = ["channel": self.users[sender.tag].uid, "event": Events.newMessage.rawValue, "message": "New Match"]
                            Alamofire.request("https://us-central1-lesbian-dating-app.cloudfunctions.net/triggerPusherChannel", method: .post, parameters: parameters2, encoding: URLEncoding.default)
                        })
                    }
                }
            } else {
                self.stopSpinner()
                let nextViewController = GetPremiumViewController()
                let customBlurFadeInPresentation = JellyFadeInPresentation(dismissCurve: .easeInEaseOut, presentationCurve: .easeInEaseOut, backgroundStyle: .blur(effectStyle: .light))
                self.jellyAnimator = JellyAnimator(presentation: customBlurFadeInPresentation)
                self.jellyAnimator?.prepare(viewController: nextViewController)
                self.present(nextViewController, animated: true, completion: nil)
            }
        })
    }
    
    fileprivate func timeString(time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
    }
    
    @objc func showFilters() {
        let filterViewController = FilterViewController()
        filterViewController.delegate = self
        filterViewController.user = user
        let navigationController = UINavigationController(rootViewController: filterViewController)
        self.present(navigationController, animated: false, completion: nil)
    }
}

extension MatchViewController2: UITableViewDelegate, UITableViewDataSource, MatchCellDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let user = user else { return }
        AnalyticsManager.shared.logEvent(name: AnalyticsEvents.userViewedProfile, user: user)
        let nextViewController = CardFullscreenViewController()
        nextViewController.user = self.users[indexPath.row]
        nextViewController.me = user
        let customBlurFadeInPresentation = JellyFadeInPresentation(dismissCurve: .easeInEaseOut, presentationCurve: .easeInEaseOut, backgroundStyle: .blur(effectStyle: .light))
        self.jellyAnimator = JellyAnimator(presentation: customBlurFadeInPresentation)
        self.jellyAnimator?.prepare(viewController: nextViewController)
        present(nextViewController, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MatchCell.reuseID) as! MatchCell
        cell.delegate = self
        cell.userImageView.sd_setImage(with: URL(string: (users[indexPath.row].images.first)!.url), placeholderImage: UIImage(named: "Placeholder_Image"))
        cell.nameAndAgeLabel.text = "\(users[indexPath.row].name), \(users[indexPath.row].age)"
        cell.locationLabel.text = users[indexPath.row].location.city
        guard let user = user else { return UITableViewCell() }
        guard let likes = user.likes else { return UITableViewCell() }
        if likes.contains(users[indexPath.row].uid) {
            cell.likeButton.setImage(UIImage(named: "Like"), for: .normal)
            cell.likeButton.isUserInteractionEnabled = false
        } else {
            cell.likeButton.setImage(UIImage(named: "Like_Disabled"), for: .normal)
            cell.likeButton.isUserInteractionEnabled = true
        }
        cell.likeButton.addTarget(self, action: #selector(self.likeTouchUpInside(_:)), for: .touchUpInside)
        cell.likeButton.tag = indexPath.row
        return cell
    }
}

protocol MatchCellDelegate: class {
    func likeTouchUpInside(_ sender: MatchCell)
}
