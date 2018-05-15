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

class MatchViewController2: UIViewController, MatchViewControllerDelegate {
    
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
    private var timer = Timer()
    private var handle: AuthStateDidChangeListenerHandle?
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavigationBar()
        setupMatchView()
        setupNoUsersState()
        setupLikesWidget()
        runLikesWidget()
        
        let tabArray = self.tabBarController?.tabBar.items as NSArray?
        let tabItem = tabArray?.object(at: 1) as! UITabBarItem
        tabItem.badgeValue = "34"
        
//        try! Auth.auth().signOut()
        handle = Auth.auth().addStateDidChangeListener { auth, user in
            if let user = user {
                Firestore.firestore().collection("users").document(user.uid).getDocument { documentSnapshot, error in
                    guard let document = documentSnapshot else {
                        print("Error fetching document: \(error!)")
                        return
                    }
                    guard let data = document.data() else {
                        self.presentRegisterViewController()
                        return
                    }
                    
                    guard let isOnboarded = data["isOnboarded"] as? Bool else {
                        print("Problem with parsing isOnboarded.")
                        return
                    }
                    
                    // Get all users and reload tableView
                    self.fetchUsers(for: user.uid)
                    self.runLikesWidget()
                    
                    if isOnboarded {
                        Firestore.firestore().collection("users").document(user.uid).getDocument { documentSnapshot, error in
                            guard let document = documentSnapshot else {
                                print("Error fetching document: \(error!)")
                                return
                            }
                            FirestoreManager.shared.parseFirebaseUser(document: document).then({ (user) in
                                self.user = user!
                            })
                        }
                    } else {
                        self.presentRegisterViewController()
                    }
                }
            } else {
                self.presentRegisterViewController()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear")
    }
    
    // MARK: - Methods
    private func presentRegisterViewController() {
        let registerViewController = RegisterViewController()
        registerViewController.imageGalleryViewController = ImagesViewController()
        registerViewController.imageGalleryViewController?.matchViewControllerDelegate = self
        let navigationController = UINavigationController(rootViewController: registerViewController)
        self.present(navigationController, animated: false, completion: nil)
    }
    
    @objc func refreshTableView() {
        guard let user = user else {
            print("No user. Error happened.")
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
    
    private func runLikesWidget() {
        guard let me = Auth.auth().currentUser else { return }
        Firestore.firestore().collection("users").document(me.uid)
            .addSnapshotListener { documentSnapshot, error in
                print("Listener deteced change")
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
                guard let data = document.data() else { return }
                
                guard let likesLeft = data["likesLeft"] as? Int else {
                    print("Problem with parsing likesLeft.")
                    return
                }
                
                guard let cooldownTime = data["cooldownTime"] as? String else {
                    print("Problem with parsing likesLeft.")
                    return
                }
                
                // Calculate whether to show number or a counter
                if likesLeft <= 0 {
                    // Show countdown
                    self.runTimer(cooldownTime: cooldownTime)
                    self.likesCounterWidgetImageView.image = UIImage(named: "Like_Disabled")
                } else {
                    // Show likesLeft
                    self.likesCounterWidgetLabel.text = "\(likesLeft)"
                    self.likesCounterWidgetImageView.image = UIImage(named: "Like")
                }
                
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
            make.top.equalTo(matchYourImageView.snp.bottom).offset(32)
            make.centerX.equalToSuperview()
        }
        matchLabel.text = "Match"
        matchLabel.font = UIFont.systemFont(ofSize: 28, weight: .heavy)
        
        matchView.addSubview(matchDescriptionLabel)
        matchDescriptionLabel.snp.makeConstraints { (make) in
            make.top.equalTo(matchLabel.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().inset(24)
            make.right.equalToSuperview().offset(-24)
        }
        matchDescriptionLabel.text = "Niiiiceee! You can go and chat or continue browsing."
        matchDescriptionLabel.font = UIFont.systemFont(ofSize: 21, weight: .regular)
        matchDescriptionLabel.numberOfLines = 2
        matchDescriptionLabel.textAlignment = .center
        
        matchView.addSubview(matchCTA)
        matchCTA.snp.makeConstraints { (make) in
            make.top.equalTo(matchDescriptionLabel.snp.bottom).offset(32)
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
        refreshControl.endRefreshing()
        FirestoreManager.shared.fetchUser(uid: uid).then { (user) in
            self.user = user
            FirestoreManager.shared.fetchPotentialMatches(for: user).then({ (users) in
                self.users = users
                print(users)
                if users.count > 0 {
                    self.hideEmptyState()
                    self.tableView.reloadData()
                } else {
                    self.showEmptyState()
                }
            })
        }
    }
    
    @objc private func runTimer(cooldownTime: String) {
        timer.invalidate()
        let timeWhenZeroHappened = cooldownTime.date(format: .custom("yyyy-MM-dd HH:mm:ss"))?.absoluteDate
        let timeUntilNewLikesUnlock = timeWhenZeroHappened?.add(components: 10.seconds)
        let differenceBetweenNowAndTimeUntilNewLikesUnlock = timeUntilNewLikesUnlock?.timeIntervalSinceNow
        seconds = Int(differenceBetweenNowAndTimeUntilNewLikesUnlock!)
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
        let cell = tableView.cellForRow(at: IndexPath(row: sender.tag, section: 0)) as! MatchCell
        cell.likeButton.transform = CGAffineTransform(scaleX: -1, y: 1)
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
            cell.likeButton.transform = CGAffineTransform(scaleX: 1,y: 1)
        })
        if let me = user {
            FirestoreManager.shared.checkIfUserHasAvailableMatches(for: me.uid).then { (success) in
                if success {
                    FirestoreManager.shared.classicUpdateLike(myUid: me.uid, herUid: self.users[sender.tag].uid).then { (success) in
                        if success {
                            FirestoreManager.shared.fetchUser(uid: me.uid).then({ (user) in
                                self.user = user
                                UIView.performWithoutAnimation {
                                    self.tableView.reloadRows(at: [IndexPath(row: sender.tag, section: 0)], with: .top)
                                    FirestoreManager.shared.checkIfLikedUserIsMatch(currentUserUid: me.uid, likedUserUid: self.users[sender.tag].uid).then({ (success) in
                                        if success {
                                            self.addImagesToMatch(myUrl: me.images.first!.url, herUrl: self.users[sender.tag].images.first!.url)
                                            self.showMatch()
                                        }
                                    })
                                    
                                }
                                
                            })
                        }
                    }
                } else {
                    // No likes left. Show Premium screen.
                    let nextViewController = GetPremiumViewController()
                    let customBlurFadeInPresentation = JellyFadeInPresentation(dismissCurve: .easeInEaseOut, presentationCurve: .easeInEaseOut, backgroundStyle: .blur(effectStyle: .light))
                    self.jellyAnimator = JellyAnimator(presentation: customBlurFadeInPresentation)
                    self.jellyAnimator?.prepare(viewController: nextViewController)
                    self.present(nextViewController, animated: true, completion: nil)
                }
            }
        }
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
        let navigationController = UINavigationController(rootViewController: filterViewController)
        self.present(navigationController, animated: false, completion: nil)
    }
}

extension MatchViewController2: UITableViewDelegate, UITableViewDataSource, MatchCellDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let nextViewController = CardFullscreenViewController()
        nextViewController.user = self.users[indexPath.row]
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
