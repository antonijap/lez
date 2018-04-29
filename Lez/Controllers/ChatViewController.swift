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

class ChatViewController: UIViewController {
    
    // Mark: - Properties
    let tableView = UITableView()
    var sections: [ChatSections] = []
    var myUid: String!
    var emptyChats: [Chat] = []
    var existingChats: [Chat] = []
    let headerTitles = ["New Chats", "Chats"]
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
                })
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
    func setupNavigationBar() {
        navigationItem.title = "Chat"
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
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return emptyChats.count
        } else {
            return existingChats.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section < headerTitles.count {
            return headerTitles[section]
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40.0
    }
    
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let header = UIView()
//        view.addSubview(header)
//        header.snp.makeConstraints { (make) in
//            make.edges.equalToSuperview()
//        }
//        header.backgroundColor = .yellow
//        return view
//    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        
        if indexPath.section == 0 {
            let newChatCell = tableView.dequeueReusableCell(withIdentifier: NewChatCell.reuseID) as! NewChatCell
            var notMe: User?
            for participant in emptyChats[indexPath.row].participants {
                if participant.uid != myUid {
                    notMe = participant
                }
            }
            newChatCell.titleLabel.text = notMe?.name
            cell = newChatCell
        } else {
            let chatCell = tableView.dequeueReusableCell(withIdentifier: ChatCell.reuseID) as! ChatCell
            var notMe: User?
            for participant in existingChats[indexPath.row].participants {
                if participant.uid != myUid {
                    notMe = participant
                }
            }
            chatCell.titleLabel.text = notMe?.name
            chatCell.messageLabel.text = existingChats[indexPath.row].messages?.last?.message
            chatCell.timeLabel.text = existingChats[indexPath.row].lastUpdated.dateValue().toString(dateFormat: "dd/MM")
            cell = chatCell
        }
        
//        if chats[indexPath.row].messages == nil {
//            let newChatCell = tableView.dequeueReusableCell(withIdentifier: NewChatCell.reuseID) as! NewChatCell
//            var notMe: User?
//            for participant in chats[indexPath.row].participants {
//                if participant.uid != myUid {
//                    notMe = participant
//                }
//            }
//            newChatCell.titleLabel.text = notMe?.name
//            cell = newChatCell
//        } else {
//            let chatCell = tableView.dequeueReusableCell(withIdentifier: ChatCell.reuseID) as! ChatCell
//            var notMe: User?
//            for participant in chats[indexPath.row].participants {
//                if participant.uid != myUid {
//                    notMe = participant
//                }
//            }
//            chatCell.titleLabel.text = notMe?.name
//            chatCell.messageLabel.text = chats[indexPath.row].messages?.last?.message
//            cell = chatCell
//        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let messagesViewController = MessagesViewController()
        if indexPath.section == 0 {
            messagesViewController.participants = emptyChats[indexPath.row].participants
            messagesViewController.chatUid = emptyChats[indexPath.row].uid
        } else {
            messagesViewController.participants = existingChats[indexPath.row].participants
            messagesViewController.chatUid = existingChats[indexPath.row].uid
        }

        messagesViewController.hidesBottomBarWhenPushed = true
        messagesViewController.view.backgroundColor = .white
        navigationController?.pushViewController(messagesViewController, animated: true)
    }
}
