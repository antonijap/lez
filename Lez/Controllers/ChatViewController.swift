//
//  ChatViewController.swift
//  Lez
//
//  Created by Antonija on 31/03/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import UIKit
import Firebase
import Promises
import SwiftDate
import moa
import JGProgressHUD
import Alamofire
import SwiftyJSON
import Alamofire_SwiftyJSON

class ChatViewController: UIViewController {
    
    // Mark: - Properties
    private let tableView = UITableView()
    private var sections: [ChatSections] = []
    private var myUid: String!
    private var emptyChats: [Chat] = []
    private var existingChats: [Chat] = []
    private let headerTitles = ["New Matches", "Chat"]
    private let hud = JGProgressHUD(style: .dark)
    private let illustration = UIImageView()
    private let label = UILabel()
    private let refreshControl = UIRefreshControl()
    
    
    // Mark: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavigationBar()
        setupTableView()
        
//        Alamofire.request("https://us-central1-lesbian-dating-app.cloudfunctions.net/addMessage", method: .post).responseJSON { (response) in
//            print("Response")
//            print(response.value)
//        }

        guard let currentUser = Auth.auth().currentUser else { return }
        self.myUid = currentUser.uid
        
        Firestore.firestore().collection("chats").whereField("participants.\(myUid!)", isEqualTo: true)
            .addSnapshotListener { querySnapshot, error in
                guard let _ = querySnapshot?.documents else {
                    print("Error fetching documents: \(error!)")
                    return
                }
                self.fetchChats()
        }
    }
    
    // Mark: - Methods
    
    @objc fileprivate func refreshChats(_ sender: Any) {
        fetchChats()
    }

    fileprivate func fetchChats() {
        guard let currentUser = Auth.auth().currentUser else { return }
        myUid = currentUser.uid
        FirestoreManager.shared.fetchUser(uid: currentUser.uid).then { (user) in
            guard let chats = user.chats else { return }
            if chats.count > 0 {
                FirestoreManager.shared.fetchChats(chats: chats).then({ (chats) in
                    self.emptyChats.removeAll()
                    self.existingChats.removeAll()
                    
                    for c in chats {
                        if c.messages == nil {
                            self.emptyChats.append(c)
                        } else {
                            self.existingChats.append(c)
                        }
                    }
                    
                    self.existingChats.sort(by: { (a, b) -> Bool in
                        a.lastUpdated.dateValue() > b.lastUpdated.dateValue()
                    })
                    
                    self.emptyChats.sort(by: { (a, b) -> Bool in
                        a.lastUpdated.dateValue() > b.lastUpdated.dateValue()
                    })
                    self.hideEmptyState()
                    self.tableView.isHidden = false
                    self.tableView.reloadData()
                    self.stopSpinner()
                    self.refreshControl.endRefreshing()
                })
            } else if chats.isEmpty {
                self.showEmptyState()
            } else {
                self.hideEmptyState()
                self.tableView.isHidden = false
            }
        }
    }
    
    fileprivate func showEmptyState() {
        if emptyChats.isEmpty && existingChats.isEmpty {
            tableView.isHidden = true
            
            view.addSubview(illustration)
            illustration.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.width.height.equalTo(64)
                make.top.equalToSuperview().inset(view.frame.height / 4.0)
            }
            illustration.image = UIImage(named: "EmptyChat")
            
            view.addSubview(label)
            label.snp.makeConstraints { (make) in
                make.top.equalTo(illustration.snp.bottom).offset(24)
                make.left.equalToSuperview().offset(32)
                make.right.equalToSuperview().inset(32)
            }
            label.text = "When you get your first match, you will be able to chat here. Keep on liking!"
            label.numberOfLines = 3
            label.textColor = .gray
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 21, weight: .medium)
        }
    }
    
    fileprivate func hideEmptyState() {
        illustration.isHidden = true
        label.isHidden = true
    }

    fileprivate func startSpinner() {
        hud.textLabel.text = "Loading"
        hud.show(in: self.view)
    }
    
    fileprivate func stopSpinner() {
        hud.dismiss(animated: true)
    }
    
    fileprivate func setupNavigationBar() {
        navigationItem.title = "Chats & Matches"
        navigationController?.navigationBar.backgroundColor = .white
        navigationController?.navigationBar.setBackgroundImage(UIImage(named: "White"), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layer.masksToBounds = false
        navigationController?.navigationBar.layer.shadowColor = UIColor(red:0.90, green:0.90, blue:0.90, alpha:1.00).cgColor
        navigationController?.navigationBar.layer.shadowOpacity = 0.8
        navigationController?.navigationBar.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        navigationController?.navigationBar.layer.shadowRadius = 4
    }
    
    fileprivate func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
        }
        tableView.backgroundColor = .white
        tableView.separatorColor = .clear
        tableView.isUserInteractionEnabled = true
        let insets = UIEdgeInsets(top: 10, left: 0, bottom: 48, right: 0)
        tableView.contentInset = insets
        tableView.register(NewChatCell.self, forCellReuseIdentifier: "NewChatCell")
        tableView.register(ChatCell.self, forCellReuseIdentifier: "ChatCell")
        tableView.isHidden = true
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshChats(_:)), for: .valueChanged)
    }
}

extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if emptyChats.isEmpty {
            return 1
        } else {
            return 2
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if emptyChats.isEmpty {
            return existingChats.count
        } else {
            if section == 0 {
                return emptyChats.count
            } else {
                return existingChats.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if emptyChats.isEmpty {
            return "Chats"
        } else {
            if section < headerTitles.count {
                return headerTitles[section]
            }
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40.0
    }
    
    fileprivate func showLastMessage(chatUid: String) -> Promise<[Message]> {
        return Promise { fulfill, reject in
            var messages = [Message]()
            let group = DispatchGroup()
            let docRef = Firestore.firestore().collection("chats").document(chatUid).collection("messages").order(by: "created")
            docRef.getDocuments { (snapshot, error) in
                guard let document = snapshot else {
                    print("Error fetching document: \(error!)")
                    reject(error!)
                    return
                }
                for message in document.documents {
                    group.enter()
                    FirestoreManager.shared.parseMessage(document: message).then({ (message) in
                        messages.append(message)
                        group.leave()
                    })
                }
                group.notify(queue: .main, execute: {
                    fulfill(messages)
                })
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        
        if emptyChats.isEmpty {
            let chatCell = tableView.dequeueReusableCell(withIdentifier: ChatCell.reuseID) as! ChatCell
            var notMe: User?
            for participant in existingChats[indexPath.row].participants {
                if participant.uid != myUid {
                    notMe = participant
                }
            }
            
            self.showLastMessage(chatUid: self.existingChats[indexPath.row].uid).then({ (messages) in
                chatCell.messageLabel.text = messages.last!.message
            })
            
            chatCell.titleLabel.text = notMe?.name
            chatCell.timeLabel.text = existingChats[indexPath.row].lastUpdated.dateValue().colloquialSinceNow()
            chatCell.userPictureView.moa.url = notMe?.images?.first
            cell = chatCell
        } else {
            if indexPath.section == 0 {
                let newChatCell = tableView.dequeueReusableCell(withIdentifier: NewChatCell.reuseID) as! NewChatCell
                var notMe: User?
                for participant in emptyChats[indexPath.row].participants {
                    if participant.uid != myUid {
                        notMe = participant
                    }
                }
                newChatCell.titleLabel.text = notMe?.name
                newChatCell.userPictureView.moa.url = notMe?.images?.first
                
                cell = newChatCell
            } else {
                let chatCell = tableView.dequeueReusableCell(withIdentifier: ChatCell.reuseID) as! ChatCell
                var notMe: User?
                for participant in existingChats[indexPath.row].participants {
                    if participant.uid != myUid {
                        notMe = participant
                    }
                }
                
                self.showLastMessage(chatUid: self.existingChats[indexPath.row].uid).then({ (messages) in
                    chatCell.messageLabel.text = messages.last?.message
                })
                
                chatCell.titleLabel.text = notMe?.name
                chatCell.timeLabel.text = existingChats[indexPath.row].lastUpdated.dateValue().colloquialSinceNow()
                chatCell.userPictureView.moa.url = notMe?.images?.first
                
                cell = chatCell
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let messagesViewController = MessagesViewController()
        
        if emptyChats.isEmpty {
            messagesViewController.participants = existingChats[indexPath.row].participants
            messagesViewController.chatUid = existingChats[indexPath.row].uid
        } else {
            if indexPath.section == 0 {
                messagesViewController.participants = emptyChats[indexPath.row].participants
                messagesViewController.chatUid = emptyChats[indexPath.row].uid
            } else {
                messagesViewController.participants = existingChats[indexPath.row].participants
                messagesViewController.chatUid = existingChats[indexPath.row].uid
            }
        }
        
        messagesViewController.hidesBottomBarWhenPushed = true
        messagesViewController.view.backgroundColor = .white
        let backButton = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        navigationController?.pushViewController(messagesViewController, animated: true)
    }
}
