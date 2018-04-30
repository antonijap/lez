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

class ChatViewController: UIViewController {
    
    // Mark: - Properties
    let tableView = UITableView()
    var sections: [ChatSections] = []
    var myUid: String!
    var emptyChats: [Chat] = []
    var existingChats: [Chat] = []
    let headerTitles = ["New Matches", "Chat"]
    let hud = JGProgressHUD(style: .dark)
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        startSpinner()
        guard let currentUser = Auth.auth().currentUser else { return }
        
        FirestoreManager.shared.fetchUser(uid: currentUser.uid).then { (user) in
            self.myUid = user.uid
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

                    self.tableView.reloadData()
                    self.stopSpinner()
                })
            } else {
                self.stopSpinner()
            }
        }
    }
    
    // Mark: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavigationBar()
        setupTableView()
    }
    
    // Mark: - Methods
    func startSpinner() {
        hud.textLabel.text = "Loading"
        hud.show(in: self.view)
    }
    
    func stopSpinner() {
        hud.dismiss(animated: true)
    }
    
    func setupNavigationBar() {
        navigationItem.title = "Chats & Matches"
        navigationController?.navigationBar.backgroundColor = .white
        navigationController?.navigationBar.setBackgroundImage(UIImage(named: "White"), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    func setupTableView() {
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
    
    func showLastMessage(chatUid: String) -> Promise<[Message]> {
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
                chatCell.messageLabel.text = messages.last?.message
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
