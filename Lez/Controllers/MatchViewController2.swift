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

class MatchViewController2: UIViewController, GetPremiumViewControllerDelegate {
    
    
    func refreshKolodaData() {
        tableView.reloadData()
    }
    
    func showTimer() {
        
    }
    
    
    // MARK: - Properties
    let tableView = UITableView()
    var users: [User] = []
    var me: User?
    var jellyAnimator: JellyAnimator?
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavigationBar()
        
        // Get all users and reload tableView
        guard let currentUser = Auth.auth().currentUser else { return }
        fetchUsers(for: currentUser.uid)
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
    
    private func fetchUsers(for uid: String) {
        FirestoreManager.shared.fetchUser(uid: uid).then { (user) in
            self.me = user
            FirestoreManager.shared.fetchPotentialMatches(for: user).then({ (users) in
                self.users = users
                self.tableView.reloadData()
            })
        }
    }
    
    private func updateLike(myUid: String, herUid: String) -> Promise<Bool> {
        return Promise { fulfill, reject in
            let ref = Firestore.firestore().collection("users").document(myUid)
            
            Firestore.firestore().runTransaction({ (transaction, errorPointer) -> Any? in
                let sfDocument: DocumentSnapshot
                do {
                    try sfDocument = transaction.getDocument(ref)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }
                
                guard let oldLikes = sfDocument.data()?["likes"] as? [String] else {
                    let error = NSError(
                        domain: "AppErrorDomain",
                        code: -1,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Unable to retrieve likes from snapshot \(sfDocument)"
                        ]
                    )
                    errorPointer?.pointee = error
                    return nil
                }
                var newLikes = oldLikes
                newLikes.append(herUid)
                transaction.updateData(["likes": newLikes], forDocument: ref)
                return nil
            }) { (object, error) in
                if let error = error {
                    print("Transaction failed: \(error)")
                    reject(error)
                } else {
                    print("Transaction successfully committed!")
                    fulfill(true)
                }
            }
        }
    }
}

extension MatchViewController2: UITableViewDelegate, UITableViewDataSource, MatchCellDelegate {
    @objc func likeTapped(_ sender: MatchCell) {
        if let me = me {
            if let likes = me.likes {
                var previousLikes: [String] = []
                previousLikes = likes
                previousLikes.append(users[sender.tag].uid)
                let data: [String: Any] = [
                    "likesLeft": me.likesLeft - 1,
                    "likes": previousLikes
                ]
                print(data)
                self.updateLike(myUid: me.uid, herUid: users[sender.tag].uid).then { (success) in
                    FirestoreManager.shared.fetchUser(uid: me.uid).then { (user) in
                        self.me = user
                        UIView.performWithoutAnimation {
                            self.tableView.reloadRows(at: [IndexPath(row: sender.tag, section: 0)], with: .none)
                        }
                        
                    }
                }
                
//                FirestoreManager.shared.updateUser(uid: me.uid, data: data).then { (success) in
//                    if success {
//                        let affectedCell = self.tableView.cellForRow(at: IndexPath(row: sender.tag, section: 0)) as? MatchCell
//                        affectedCell?.likeButton.setImage(UIImage(named: "Like"), for: .normal)
//                        sender.likeButton.setImage(UIImage(named: "Like"), for: .normal)
//                    }
//                }
            }
        }
    }
    
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
        cell.userImageView.moa.url = users[indexPath.row].images.first
        cell.nameAndAgeLabel.text = "\(users[indexPath.row].name), \(users[indexPath.row].age)"
        cell.locationLabel.text = users[indexPath.row].location.city
        guard let user = me else { return UITableViewCell() }
        guard let likes = user.likes else { return UITableViewCell() }
        if likes.contains(users[indexPath.row].uid) {
            cell.likeButton.setImage(UIImage(named: "Like"), for: .normal)
        } else {
            cell.likeButton.setImage(UIImage(named: "Like_Disabled"), for: .normal)
        }
        cell.likeButton.addTarget(self, action: #selector(self.likeTapped(_:)), for: .touchUpInside)
        cell.likeButton.tag = indexPath.row
        return cell
    }
    

}

protocol MatchCellDelegate: class {
    func likeTapped(_ sender: MatchCell)
}
