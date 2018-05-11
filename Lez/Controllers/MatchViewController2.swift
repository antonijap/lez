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
import moa
import Jelly
import Promises
import Alamofire
import AlamofireImage
import SwiftDate
import SDWebImage

class MatchViewController2: UIViewController, GetPremiumViewControllerDelegate {
    
    
    func refreshKolodaData() {
        tableView.reloadData()
    }
    
    func showTimer() {
        
    }
    
    
    // MARK: - Properties
    let tableView = UITableView()
    let likesCounterWidgetView = UIView()
    let likesCounterWidgetImageView = UIImageView()
    let likesCounterWidgetLabel = UILabel()
    var users: [User] = []
    var me: User?
    var jellyAnimator: JellyAnimator?
    var seconds = 86400
    var timer = Timer()
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavigationBar()
        // Get all users and reload tableView
        guard let currentUser = Auth.auth().currentUser else { return }
        fetchUsers(for: currentUser.uid)
        setupLikesWidget()
        
        guard let me = Auth.auth().currentUser else { return }
        Firestore.firestore().collection("users").document(me.uid)
            .addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
                let newUser = FirestoreManager.shared.parseFirebaseUser(document: document)
                self.me = newUser
        }
    }
    
    // MARK: - Methods
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
    }
    
    private func setupNavigationBar() {
        let filterButton = UIButton(type: .custom)
        filterButton.setImage(UIImage(named: "Filter"), for: .normal)
        filterButton.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        let rightItem = UIBarButtonItem(customView: filterButton)
        self.navigationItem.title = "Match Room"
        self.navigationItem.setRightBarButtonItems([rightItem], animated: true)
        self.navigationController?.navigationBar.backgroundColor = .white
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
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
        
        guard let me = Auth.auth().currentUser else { return }
        Firestore.firestore().collection("users").document(me.uid)
            .addSnapshotListener { documentSnapshot, error in
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
                
        likesCounterWidgetView.layoutIfNeeded()
    }
    
    private func fetchUsers(for uid: String) {
        FirestoreManager.shared.fetchUser(uid: uid).then { (user) in
            self.me = user
            FirestoreManager.shared.fetchPotentialMatches(for: user).then({ (users) in
                self.users = users
                self.tableView.reloadData()
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
            guard let user = me else { return }
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
        if let me = me {
            FirestoreManager.shared.checkIfUserHasAvailableMatches(for: me.uid).then { (success) in
                if success {
                    FirestoreManager.shared.classicUpdateLike(myUid: me.uid, herUid: self.users[sender.tag].uid).then { (success) in
                        if success {
                            UIView.performWithoutAnimation {
                                //  let affectedCell = self.tableView.cellForRow(at: IndexPath(row: sender.tag, section: 0)) as? MatchCell
                                //  affectedCell?.likeButton.setImage(UIImage(named: "Like"), for: .normal)
                                self.tableView.reloadRows(at: [IndexPath(row: sender.tag, section: 0)], with: .top)
                            }
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
        cell.userImageView.sd_setImage(with: URL(string: users[indexPath.row].images.first!), placeholderImage: UIImage(named: "Placeholder_Image"))
        cell.nameAndAgeLabel.text = "\(users[indexPath.row].name), \(users[indexPath.row].age)"
        cell.locationLabel.text = users[indexPath.row].location.city
        guard let user = me else { return UITableViewCell() }
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
