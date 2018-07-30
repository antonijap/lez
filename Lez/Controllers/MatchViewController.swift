//
//  MatchViewController.swift
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

final class MatchViewController: UIViewController, MatchViewControllerDelegate, PusherDelegate {
    
    // MARK: - Properties
    private let tableView = UITableView()
    private let likesCounterWidgetView = UIView()
    private let likesCounterWidgetImageView = UIImageView()
    private let likesCounterWidgetLabel = UILabel()
    private let matchYourImageView = SpringImageView()
    private let matchHerImageView = SpringImageView()
    private let matchLabel = UILabel()
    private let matchCTA = PrimaryButton()
    private let matchCloseButton = UIButton()
    private let matchView = SpringView()
    private let matchOverlayView = SpringView()
    private let matchDescriptionLabel = SpringLabel()
    private let matchSubtitle = SpringLabel()
    private let noUsersBackground = UIImageView()
    private let noUsersTitle = UILabel()
    private let noUsersDescription = UILabel()
    private let noUsersCTA = PrimaryButton()
    private let noUsersRefreshButton = SpringButton()
    private let refreshControl = UIRefreshControl()
    private var users: [User] = []
    private var user: User?
    private var jellyAnimator: JellyAnimator?
    private var seconds = 86400
    private var handle: AuthStateDidChangeListenerHandle?
    private let hud = JGProgressHUD(style: .dark)
    private var pusher = Pusher(key: "b5bd116d3da803ac6d12", options: PusherClientOptions(host: .cluster("eu")))
    private var canLike: Bool!
    private var likesLeft: Int!
    private var timer = Timer()
    private var refreshButton = PrimaryButton()
    
    // MARK: - Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let currentUser = Auth.auth().currentUser {
            FirestoreManager.shared.fetchUser(uid: currentUser.uid).then { user in
                self.user = user
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
        guard Auth.auth().currentUser != nil else { return }
        guard user != nil else { return }
        pusher.disconnect()
        super.viewWillDisappear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !DefaultsManager.shared.ifToggleAllLesbiansExists() {
            DefaultsManager.shared.saveToggleAllLesbians(value: false)
        }
        if !DefaultsManager.shared.ifTrackingPreferenceExists() {
            DefaultsManager.shared.saveTrackingPreference(value: true)
        }
        setupTableView()
        setupNavigationBar()
        setupMatchView()
        setupNoUsersState()
        setupLikesWidget()
        setupRefreshButton()
        
        DefaultsManager.shared.save(number: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshTableView), name: Notification.Name("RefreshTableView"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateAfterAppComesToForeground),
                                               name: .UIApplicationWillEnterForeground, object: nil)

        handle = Auth.auth().addStateDidChangeListener { auth, user in
            guard let user = user else { self.presentRegisterViewController(); return }
            self.checkConnectivity(uid: user.uid)
        }
        
        Alertift.alert(title: "We need your consent", message: "We would like to send you a newsletter sometime, do you give us your consent to do so?")
            .action(.default("I consent"), isPreferred: true) { _, _, _ in
                // Add user to Mailchimp

            }
            .action(.destructive("No"))
            .show(on: self, completion: nil)
    }
    
    // MARK: - Methods
    
    func addUserToMailchimp(){
        
        let credentialData = "***REMOVED***-us17".data(using: String.Encoding.utf8)!
        let base64Credentials = credentialData.base64EncodedString(options: [])
        let headers = ["Authorization": "Basic \(base64Credentials)"]
        
        var urlRequest = URLRequest(url: URL(string: "***REMOVED***/lists/***REMOVED***/members/")!)
        urlRequest.httpMethod = HTTPMethod.get.rawValue
        urlRequest = try! URLEncoding.default.encode(urlRequest, with: nil)
        urlRequest.setValue("***REMOVED***-us17", forHTTPHeaderField: "Authorization")
        
        guard let user = self.user else { return }
        
        let parameters: [String: String] = [
            "email_address": user.email,
            "status": "subscribed"
        ]
        
//        Alamofire.request(urlRequest, parameters: parameters, encoding: JSONEncoding.default, headers: headers).validate().responseJSON { response in
//            switch response.result {
//            case .success:
//                print("Validation Successful")
//            case .failure(let error):
//                print(error)
//            }
//        }
    }
    
    private func showAlertIfUserBanned(user: User) {
        if user.isBanned {
            Alertift.alert(title: "You are banned", message: "You've broken our rules and your account is banned.")
                .show()
        }
    }
    
    private func hideRefreshButton() {
        refreshButton.isHidden = true
    }
    
    private func showRefreshButton() {
        refreshButton.isHidden = false
    }
    
    @objc func refreshButtonTapped(_ sender: UIButton) {
        guard let currentUser = Auth.auth().currentUser else { return }
        checkConnectivity(uid: currentUser.uid)
    }
    
    private func hideTableView() {
        tableView.isHidden = true
        hideLikesWidget()
    }
    
    private func showTableView() {
        tableView.isHidden = false
        showLikesWidget()
    }
    
    private func checkConnectivity(uid: String) {
        if Connectivity.isConnectedToInternet {
            hideRefreshButton()
            showTableView()
            fetchUsers(for: uid)
        } else {
            Alertift.alert(title: "No Internet", message: "It seems you are not connected to network. Please try again.")
                .action(Alertift.Action.default("Okay"))
                .show(on: self) { self.hideTableView(); self.showRefreshButton() }
        }
    }
    
    func removeUserFromLocalArray(uid: String) {
        if let index = users.index(where: { $0.uid.contains(uid) }) {
            print("Will remove \(index)")
            users.remove(at: index)
            tableView.reloadData()
        }
    }
    
    func failedToSubscribeToChannel(name: String, response: URLResponse?, data: String?, error: NSError?) {
        print("FAILED to subscribe \(name), \(error.debugDescription)")
    }
    
    @objc func updateAfterAppComesToForeground() {
        print("I have come to foreground.")
        guard let currentUser = Auth.auth().currentUser else { return }
        FirestoreManager.shared.fetchUser(uid: currentUser.uid).then { user in
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
        self.present(navigationController, animated: false)
    }
    
    @objc func refreshTableView() {
        guard let user = user else {
            if let currentUser = Auth.auth().currentUser {
                FirestoreManager.shared.fetchUser(uid: currentUser.uid).then { user in
                    self.user = user
                    self.showAlertIfUserBanned(user: user) // Show alert for banned users
                    self.fetchUsers(for: user.uid)
                }
            }
            return
        }
        fetchUsers(for: user.uid)
    }

    @objc private func shareWebsite() {
        let web = NSURL(string: "http://getlez.com")
        AnalyticsManager.shared.logEvent(name: AnalyticsEvents.userSharedURL, user: user!)
        web.share()
    }

    func showLikesWidget() {
        likesCounterWidgetView.isHidden = false
    }
    
    func hideLikesWidget() {
        likesCounterWidgetView.isHidden = true
    }
    
    func runLikesWidget(uid: String) {
        Firestore.firestore().collection("users").document(uid).addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else { print("Error fetching document: \(error!)"); return }
            guard let _ = document.data() else { self.presentRegisterViewController(); return }
            FirestoreManager.shared.parseFirebaseUser(document: document).then({ user in
                guard let user = user else { print("Failed to parse user in runLikesWidget."); return }
                self.user = user
                if !user.isOnboarded { self.presentRegisterViewController() }
                if !user.isManuallyPromoted {
                    if user.isPremium {
                        print("user is PREMIUM")
                        self.stopTimer()
                        self.canLike = true
                        self.likesLeft = user.likesLeft
                        self.likesCounterWidgetLabel.text = "Unlimited"
                        self.likesCounterWidgetImageView.image = #imageLiteral(resourceName: "Like")
                    } else {
                        if user.likesLeft <= 0 {
                            // Show countdown
                            AnalyticsManager.shared.logEvent(name: AnalyticsEvents.userRunOutOfLikes, user: user)
                            self.canLike = false
                            self.likesLeft = user.likesLeft
                            guard let cooldownTime = user.cooldownTime else { return }
                            self.runTimer(cooldownTime: cooldownTime)
                            self.likesCounterWidgetImageView.image = #imageLiteral(resourceName: "Like_Disabled")
                        } else {
                            // Show likesLeft
                            self.canLike = true
                            self.likesLeft = user.likesLeft
                            self.likesCounterWidgetLabel.text = "\(self.likesLeft!)"
                            self.likesCounterWidgetImageView.image = #imageLiteral(resourceName: "Like")
                        }
                    }
                } else {
                    self.stopTimer()
                    self.canLike = true
                    self.likesCounterWidgetLabel.text = "Unlimited"
                    self.likesCounterWidgetImageView.image = #imageLiteral(resourceName: "Like")
                }
            })
        }
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
        matchYourImageView.sd_setImage(with: URL(string: myUrl), placeholderImage: #imageLiteral(resourceName: "Placeholder_Image"))
        matchHerImageView.sd_setImage(with: URL(string: herUrl), placeholderImage: #imageLiteral(resourceName: "Placeholder_Image"))
    }
    
    @objc func fetchUsers(for uid: String) {
        startSpinner()
        runLikesWidget(uid: uid)
        refreshControl.endRefreshing()
        FirestoreManager.shared.fetchUser(uid: uid).then { user in
            self.user = user
            self.showAlertIfUserBanned(user: user) // Show alert for banned users
            FirestoreManager.shared.fetchPotentialMatches(for: user).then({ users in
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
        stopTimer()
        let timeUntilNewLikesUnlock = cooldownTime.add(components: 24.hours)
        let differenceBetweenNowAndTimeUntilNewLikesUnlock = timeUntilNewLikesUnlock.timeIntervalSinceNow
        print("Difference \(differenceBetweenNowAndTimeUntilNewLikesUnlock)")
        seconds = Int(differenceBetweenNowAndTimeUntilNewLikesUnlock)
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(self.updateTimer)), userInfo: nil, repeats: true)
    }
    
    private func stopTimer() {
        timer.invalidate()
    }
    
    // Ovo ne diraj
    @objc func updateTimer() {
        if seconds <= 0 {
            print("Sekunde su manje od nule. Resetirat cu sve.")
            guard let user = user else { print("No user detected."); return }
            AnalyticsManager.shared.logEvent(name: AnalyticsEvents.userCounterReset, user: user)
            timer.invalidate()
            let data: [String: Any] = ["likesLeft": 5,
                                       "cooldownTime": ""]
            FirestoreManager.shared.updateUser(uid: user.uid, data: data).then { user in
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
            cell.likeButton.transform = CGAffineTransform(scaleX: 1, y: 1)
            guard let user = self.user else { return }
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
                
                Firestore.firestore().collection("users").document(user.uid).updateData(data) { error in
                    if let error = error {
                        print("Error updating document: \(error)")
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
                    guard let document = documentSnapshot else { print("Error fetching document: \(error!)"); return }
                    guard let data = document.data() else { return }
                    guard let likes = data["likes"] as? [String] else { print("Problem with parsing likes."); return }
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
                            Alamofire.request("https://us-central1-lesbian-dating-app.cloudfunctions.net/sendPushNotification",
                                              method: .post, parameters: parameters, encoding: URLEncoding.default)
                            let parameters2: Parameters = ["channel": self.users[sender.tag].uid, "event": Events.newMessage.rawValue, "message": "New Match"]
                            Alamofire.request("https://us-central1-lesbian-dating-app.cloudfunctions.net/triggerPusherChannel",
                                              method: .post, parameters: parameters2, encoding: URLEncoding.default)
                        })
                    }
                }
            } else {
                self.stopSpinner()
                let nextViewController = GetPremiumViewController()
                guard let user = self.user else { return }
                nextViewController.user = user
                let customBlurFadeInPresentation = JellyFadeInPresentation(dismissCurve: .easeInEaseOut, presentationCurve: .easeInEaseOut, backgroundStyle: .blur(effectStyle: .light))
                self.jellyAnimator = JellyAnimator(presentation: customBlurFadeInPresentation)
                self.jellyAnimator?.prepare(viewController: nextViewController)
                self.present(nextViewController, animated: true)
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
        self.present(navigationController, animated: false)
    }
}

extension MatchViewController: UITableViewDelegate, UITableViewDataSource, MatchCellDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let user = user else { return }
        AnalyticsManager.shared.logEvent(name: AnalyticsEvents.userViewedProfile, user: user)
        let nextViewController = CardFullscreenViewController()
        nextViewController.user = self.users[indexPath.row]
        nextViewController.me = user
        nextViewController.indexPath = indexPath
        nextViewController.delegate = self
        let customBlurFadeInPresentation = JellyFadeInPresentation(dismissCurve: .easeInEaseOut, presentationCurve: .easeInEaseOut, backgroundStyle: .blur(effectStyle: .light))
        self.jellyAnimator = JellyAnimator(presentation: customBlurFadeInPresentation)
        self.jellyAnimator?.prepare(viewController: nextViewController)
        present(nextViewController, animated: true)
        
//        if Device.isPad() {
//
//        } else {
//            guard let user = user else { return }
//            AnalyticsManager.shared.logEvent(name: AnalyticsEvents.userViewedProfile, user: user)
//            let nextViewController = CardFullscreenViewController()
//            nextViewController.user = self.users[indexPath.row]
//            nextViewController.me = user
//            nextViewController.indexPath = indexPath
//            nextViewController.delegate = self
//            let customBlurFadeInPresentation = JellyFadeInPresentation(dismissCurve: .easeInEaseOut, presentationCurve: .easeInEaseOut, backgroundStyle: .blur(effectStyle: .light))
//            self.jellyAnimator = JellyAnimator(presentation: customBlurFadeInPresentation)
//            self.jellyAnimator?.prepare(viewController: nextViewController)
//            present(nextViewController, animated: true)
//        }
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
        guard let firstImage = users[indexPath.row].images.first else { return UITableViewCell() }
        cell.userImageView.sd_setImage(with: URL(string: firstImage.url), placeholderImage: UIImage(named: "Placeholder_Image"))
        cell.nameAndAgeLabel.text = "\(users[indexPath.row].name), \(users[indexPath.row].age)"
        cell.locationLabel.text = "\(users[indexPath.row].location.city), \(users[indexPath.row].location.country)"
        guard let user = user else { return UITableViewCell() }
        guard let likes = user.likes else { return UITableViewCell() }
        if likes.contains(users[indexPath.row].uid) {
            cell.likeButton.setImage(UIImage(named: "Like"), for: .normal)
            cell.likeButton.isUserInteractionEnabled = false
        } else {
            cell.likeButton.setImage(UIImage(named: "Like_Disabled"), for: .normal)
            cell.likeButton.isUserInteractionEnabled = true
        }
        cell.likeButton.addTarget(self, action: #selector(self.likeTouchUpInside(_:)), for: .primaryActionTriggered)
        cell.likeButton.tag = indexPath.row
        return cell
    }
}

protocol MatchCellDelegate: class {
    func likeTouchUpInside(_ sender: MatchCell)
}

extension MatchViewController {
    private func setupNoUsersState() {
        view.addSubview(noUsersBackground)
        noUsersBackground.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
            make.leading.trailing.equalToSuperview()
        }
        noUsersBackground.image = UIImage(named: "No_Users_Background")
        noUsersBackground.contentMode = .scaleAspectFill
        noUsersBackground.clipsToBounds = true
        
        view.addSubview(noUsersTitle)
        noUsersTitle.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(view.frame.height / 3.0)
            make.centerX.equalToSuperview()
        }
        noUsersTitle.text = "Bummer"
        noUsersTitle.font = UIFont.systemFont(ofSize: 28, weight: .heavy)
        
        view.addSubview(noUsersDescription)
        noUsersDescription.snp.makeConstraints { make in
            make.top.equalTo(noUsersTitle.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(32)
            make.trailing.equalToSuperview().inset(32)
        }
        noUsersDescription.text = "No lesbians with your criteria. Try changing preferences."
        noUsersDescription.numberOfLines = 2
        noUsersDescription.font = .systemFont(ofSize: 21, weight: .medium)
        noUsersDescription.textAlignment = .center
        
        view.addSubview(noUsersCTA)
        noUsersCTA.snp.makeConstraints { make in
            make.top.equalTo(noUsersDescription.snp.bottom).offset(32)
            make.leading.equalToSuperview().offset(48)
            make.trailing.equalToSuperview().inset(48)
            make.height.equalTo(48)
        }
        noUsersCTA.setTitle("Spread Word", for: .normal)
        noUsersCTA.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        let buttonTap = UITapGestureRecognizer(target: self, action: #selector(self.shareWebsite))
        noUsersCTA.addGestureRecognizer(buttonTap)
        
        view.addSubview(noUsersRefreshButton)
        noUsersRefreshButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin).inset(32)
            make.centerX.equalToSuperview()
        }
        noUsersRefreshButton.setTitle("Try refresh?", for: .normal)
        noUsersRefreshButton.addTarget(self, action: #selector(self.refreshTableView), for: .primaryActionTriggered)
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
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
        }
        tableView.register(MatchCell.self, forCellReuseIdentifier: "MatchCell")
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(self.refreshTableView), for: .valueChanged)
        hideTableView()
    }
    
    private func setupNavigationBar() {
        navigationItem.title = "Match Room"
        navigationController?.navigationBar.backgroundColor = .white
        navigationController?.navigationBar.setBackgroundImage(#imageLiteral(resourceName: "White"), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layer.masksToBounds = false
        navigationController?.navigationBar.layer.shadowColor = UIColor(red:0.90, green:0.90, blue:0.90, alpha:1.00).cgColor
        navigationController?.navigationBar.layer.shadowOpacity = 0.8
        navigationController?.navigationBar.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        navigationController?.navigationBar.layer.shadowRadius = 4
        let filterButton = UIButton(type: .custom)
        filterButton.setImage(#imageLiteral(resourceName: "Filter"), for: .normal)
        filterButton.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        filterButton.addTarget(self, action: #selector(self.showFilters), for: .primaryActionTriggered)
        let rightItem = UIBarButtonItem(customView: filterButton)
        navigationItem.setRightBarButtonItems([rightItem], animated: true)
    }
    
    private func setupLikesWidget() {
        view.addSubview(likesCounterWidgetView)
        likesCounterWidgetView.snp.makeConstraints { make in
            make.height.equalTo(32)
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin).inset(16)
        }
        likesCounterWidgetView.layer.cornerRadius = 16
        likesCounterWidgetView.clipsToBounds = false
        likesCounterWidgetView.backgroundColor = .white
        likesCounterWidgetView.dropShadow()
        
        likesCounterWidgetView.addSubview(likesCounterWidgetImageView)
        likesCounterWidgetImageView.snp.makeConstraints { make in
            make.height.width.equalTo(20)
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(8)
        }
        likesCounterWidgetImageView.image = #imageLiteral(resourceName: "Like")
        
        likesCounterWidgetView.addSubview(likesCounterWidgetLabel)
        likesCounterWidgetLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(likesCounterWidgetImageView.snp.trailing).offset(4)
            make.trailing.equalToSuperview().inset(12)
        }
        
        likesCounterWidgetView.layoutIfNeeded()
    }
    
    private func setupRefreshButton() {
        view.addSubview(refreshButton)
        refreshButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(44)
            make.width.equalTo(150)
        }
        refreshButton.setTitle("Try Again", for: .normal)
        refreshButton.addTarget(self, action: #selector(self.refreshButtonTapped(_:)), for: .primaryActionTriggered)
        hideRefreshButton()
    }
    
    private func setupMatchView() {
        UIApplication.shared.keyWindow?.addSubview(matchOverlayView)
        matchOverlayView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        matchOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        UIApplication.shared.keyWindow?.addSubview(matchView)
        matchView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(32)
            make.trailing.equalToSuperview().inset(32)
            make.center.equalToSuperview()
        }
        matchView.backgroundColor = .white
        matchView.layer.cornerRadius = 8
        matchView.dropShadow()
        
        matchView.addSubview(matchYourImageView)
        matchYourImageView.snp.makeConstraints { make in
            make.height.width.equalTo(48)
            make.centerX.equalToSuperview().inset(10)
            make.top.equalToSuperview().offset(40)
        }
        matchYourImageView.backgroundColor = UIColor(red:0.77, green:0.77, blue:0.77, alpha:1.00)
        matchYourImageView.layer.cornerRadius = 48 / 2
        matchYourImageView.clipsToBounds = true
        matchYourImageView.contentMode = .scaleAspectFill
        
        matchView.addSubview(matchHerImageView)
        matchHerImageView.snp.makeConstraints { make in
            make.height.width.equalTo(48)
            make.centerX.equalToSuperview().inset(-10)
            make.top.equalTo(matchYourImageView.snp.top)
        }
        matchHerImageView.backgroundColor = UIColor(red:0.69, green:0.69, blue:0.69, alpha:1.00)
        matchHerImageView.layer.cornerRadius = 48 / 2
        matchHerImageView.clipsToBounds = true
        matchHerImageView.contentMode = .scaleAspectFill
        
        matchView.addSubview(matchLabel)
        matchLabel.snp.makeConstraints { make in
            make.top.equalTo(matchHerImageView.snp.bottom).offset(32)
            make.centerX.equalToSuperview()
        }
        matchLabel.text = "Match"
        matchLabel.font = .systemFont(ofSize: 28, weight: .heavy)
        
        matchView.addSubview(matchSubtitle)
        matchSubtitle.snp.makeConstraints { make in
            make.top.equalTo(matchLabel.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.leading.equalToSuperview().inset(24)
            make.trailing.equalToSuperview().offset(-24)
        }
        matchSubtitle.font = .systemFont(ofSize: 21, weight: .regular)
        matchSubtitle.numberOfLines = 2
        matchSubtitle.textAlignment = .center
        
        matchView.addSubview(matchCTA)
        matchCTA.snp.makeConstraints { make in
            make.top.equalTo(matchSubtitle.snp.bottom).offset(32)
            make.leading.equalToSuperview().offset(32)
            make.trailing.equalToSuperview().inset(32)
            make.height.equalTo(44)
            make.bottom.equalToSuperview().inset(40)
        }
        matchCTA.setTitle("Go to Chat", for: .normal)
        matchCTA.addTarget(self, action: #selector(self.goToChat), for: .primaryActionTriggered)
        
        matchView.addSubview(matchCloseButton)
        matchCloseButton.snp.makeConstraints { make in
            make.size.equalTo(32)
            make.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(16)
        }
        matchCloseButton.setImage(UIImage(named: "Close"), for: .normal)
        matchCloseButton.addTarget(self, action: #selector(self.closeButtonTapped(_:)), for:.primaryActionTriggered)
        
        matchView.alpha = 0
        matchOverlayView.alpha = 0
    }
}
