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
import JGProgressHUD
import Alamofire
import SwiftyJSON
import PusherSwift
import Alertift

final class ChatViewController: UIViewController {

    // Mark: - Properties

    private let tableView = UITableView()
    private var sections: [ChatSections] = []
    private var uid: String!
    private var emptyChats: [Chat] = []
    private var existingChats: [Chat] = []
    private let headerTitles = ["New Matches", "Chats"]
    private let hud = JGProgressHUD(style: .dark)
    private let refreshControl = UIRefreshControl()
    private let noChatsBackground = UIImageView()
    private let noChatsTitle = UILabel()
    private let noChatsDescription = UILabel()

    // Mark: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavigationBar()
        setupTableView()
        setupNoChats()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DefaultsManager.shared.save(number: 0)

        guard let currentUser = Auth.auth().currentUser else { return }
        self.uid = currentUser.uid

        if let tabItems = self.tabBarController?.tabBar.items as NSArray? {
            let tabItem = tabItems[1] as! UITabBarItem
            tabItem.badgeValue = nil
        }

        // Listener if you get a new chat
        Firestore.firestore().collection("users").document(uid)
            .addSnapshotListener { querySnapshot, error in
                guard let _ = querySnapshot?.data() else { print("Error fetching documents: \(error!)"); return }
                self.fetchChats() // Add a badge
        }

        // Listener for your chats
        Firestore.firestore().collection("chats").whereField("participants.\(uid!)", isEqualTo: true)
            .addSnapshotListener { querySnapshot, error in
                guard let _ = querySnapshot?.documents else { print("Error fetching documents: \(error!)"); return }
                self.fetchChats() // Add a badge
        }
    }

    // Mark: - Methods

    private func setupNoChats() {
        view.addSubview(noChatsBackground)
        noChatsBackground.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
            make.leading.trailing.equalToSuperview()
        }
        noChatsBackground.image = #imageLiteral(resourceName: "No_Chats_Background")
        noChatsBackground.contentMode = .scaleAspectFill
        noChatsBackground.clipsToBounds = true

        view.addSubview(noChatsTitle)
        noChatsTitle.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(view.frame.height / 3.0)
            make.centerX.equalToSuperview()
        }
        noChatsTitle.text = "No Chats"
        noChatsTitle.font = .systemFont(ofSize: 28, weight: .heavy)

        view.addSubview(noChatsDescription)
        noChatsDescription.snp.makeConstraints { make in
            make.top.equalTo(noChatsTitle.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(32)
            make.trailing.equalToSuperview().inset(32)
        }
        noChatsDescription.text = "Better get to liking. You can chat with matched lesbians here."
        noChatsDescription.numberOfLines = 2
        noChatsDescription.font = .systemFont(ofSize: 21, weight: .medium)
        noChatsDescription.textAlignment = .center

        hideEmptyState()
    }

    private func hideEmptyState() {
        noChatsBackground.isHidden = true
        noChatsTitle.isHidden = true
        noChatsDescription.isHidden = true
    }

    private func showEmptyState() {
        noChatsBackground.isHidden = false
        noChatsTitle.isHidden = false
        noChatsDescription.isHidden = false
    }

    @objc fileprivate func refreshChats(_ sender: Any) {
        fetchChats()
    }

    fileprivate func fetchChats() {
        guard let currentUser = Auth.auth().currentUser else { return }
        uid = currentUser.uid
        FirestoreManager.shared.fetchUser(uid: currentUser.uid).then { user in
            guard let chats = user.chats else { return }
            if chats.count > 0 {
                FirestoreManager.shared.fetchChats(chats: chats).then({ chats in
                    self.emptyChats.removeAll()
                    self.existingChats.removeAll()
                    for chat in chats {
                        if chat.messages == nil {
                            self.emptyChats.append(chat)
                        } else {
                            self.existingChats.append(chat)
                        }
                    }
                    self.existingChats.sort(by: { a, b -> Bool in
                        a.lastUpdated.date(format: .custom("yyyy-MM-dd HH:mm:ss"))! > b.lastUpdated.date(format: .custom("yyyy-MM-dd HH:mm:ss"))!
                    })
                    
                    self.emptyChats.sort(by: { a, b -> Bool in
                        a.lastUpdated.date(format: .custom("yyyy-MM-dd HH:mm:ss"))! > b.lastUpdated.date(format: .custom("yyyy-MM-dd HH:mm:ss"))!
                    })
                    self.hideEmptyState()
                    self.tableView.isHidden = false
                    self.tableView.reloadData()
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

    private func startSpinner() {
        hud.textLabel.text = "Loading"
        hud.show(in: self.view)
    }
    
    private func stopSpinner() {
        hud.dismiss(animated: true)
    }
    
    private func setupNavigationBar() {
        navigationItem.title = "Chats & Matches"
        navigationController?.navigationBar.backgroundColor = .white
        navigationController?.navigationBar.setBackgroundImage(#imageLiteral(resourceName: "White"), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layer.masksToBounds = false
        navigationController?.navigationBar.layer.shadowColor = UIColor(red:0.90, green:0.90, blue:0.90, alpha:1.00).cgColor
        navigationController?.navigationBar.layer.shadowOpacity = 0.8
        navigationController?.navigationBar.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        navigationController?.navigationBar.layer.shadowRadius = 4
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
        }
        tableView.backgroundColor = .white
        tableView.separatorColor = .clear
        tableView.isUserInteractionEnabled = true
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: 48, right: 0)
        tableView.contentInset = insets
        tableView.register(NewChatCell.self, forCellReuseIdentifier: "NewChatCell")
        tableView.register(ChatCell.self, forCellReuseIdentifier: "ChatCell")
        tableView.isHidden = true
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshChats(_:)), for: .valueChanged)
        self.fetchChats()
    }
}

extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        guard !emptyChats.isEmpty else { return 1 }
        guard existingChats.isEmpty else { return 2 }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard !emptyChats.isEmpty else { return existingChats.count }
        guard section == 0 else { return existingChats.count }
        return emptyChats.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard !emptyChats.isEmpty else { return "Chats" }
        if section < headerTitles.count { return headerTitles[section] }
        return nil
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        (view as! UITableViewHeaderFooterView).backgroundView?.backgroundColor = .white
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40.0
    }
    
    fileprivate func showLastMessage(chatUid: String) -> Promise<[Message]> {
        return Promise { fulfill, reject in
            var messages = [Message]()
            let group = DispatchGroup()
            let docRef = Firestore.firestore().collection("chats").document(chatUid).collection("messages").order(by: "created")
            docRef.getDocuments { snapshot, error in
                guard let document = snapshot else {
                    print("Error fetching document: \(error!)")
                    reject(error!); return
                }
                for message in document.documents {
                    group.enter()
                    FirestoreManager.shared.parseMessage(document: message).then({ message in
                        messages.append(message)
                        group.leave()
                    })
                }
                group.notify(queue: .main, execute: { fulfill(messages) })
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        
        if emptyChats.isEmpty {
            let chatCell = tableView.dequeueReusableCell(withIdentifier: ChatCell.reuseID) as! ChatCell
            var notMe: User?
            for participant in existingChats[indexPath.row].participants {
                if participant.uid != uid { notMe = participant }
            }
            chatCell.layer.backgroundColor = UIColor.white.cgColor
            chatCell.isUserInteractionEnabled = true
            chatCell.titleLabel.text = notMe?.name
            chatCell.timeLabel.text = existingChats[indexPath.row].lastUpdated.date(format: .custom("yyyy-MM-dd HH:mm:ss"))?.colloquialSinceNow()
            chatCell.userPictureView.sd_setImage(with: URL(string: notMe!.images.first!.url), placeholderImage: #imageLiteral(resourceName: "Placeholder_Image"))
            if existingChats[indexPath.row].isDisabled {
                chatCell.isUserInteractionEnabled = false
                chatCell.layer.backgroundColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:0.3).cgColor
                chatCell.messageLabel.text = "Deleted"
            } else {
                self.showLastMessage(chatUid: self.existingChats[indexPath.row].uid).then({ messages in
                    chatCell.messageLabel.text = messages.last!.message
                })
            }
            cell = chatCell
        } else {
            if indexPath.section == 0 {
                let newChatCell = tableView.dequeueReusableCell(withIdentifier: NewChatCell.reuseID) as! NewChatCell
                var notMe: User?
                for participant in emptyChats[indexPath.row].participants {
                    if participant.uid != uid { notMe = participant }
                }
                newChatCell.titleLabel.text = notMe?.name
                newChatCell.userPictureView.sd_setImage(with: URL(string: notMe!.images.first!.url), placeholderImage: #imageLiteral(resourceName: "Placeholder_Image"))
                newChatCell.isUserInteractionEnabled = true
                newChatCell.alpha = 1
                cell = newChatCell
            } else {
                let chatCell = tableView.dequeueReusableCell(withIdentifier: ChatCell.reuseID) as! ChatCell
                var notMe: User?
                for participant in existingChats[indexPath.row].participants {
                    if participant.uid != uid { notMe = participant }
                }
                chatCell.layer.backgroundColor = UIColor.white.cgColor
                chatCell.isUserInteractionEnabled = true
                chatCell.titleLabel.text = notMe?.name
                chatCell.timeLabel.text = existingChats[indexPath.row].lastUpdated.date(format: .custom("yyyy-MM-dd HH:mm:ss"))?.colloquialSinceNow()
                chatCell.userPictureView.sd_setImage(with: URL(string: notMe!.images.first!.url), placeholderImage: #imageLiteral(resourceName: "Placeholder_Image"))
                if existingChats[indexPath.row].isDisabled {
                    chatCell.isUserInteractionEnabled = false
                    chatCell.layer.backgroundColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:0.3).cgColor
                    chatCell.messageLabel.text = "Deleted"
                } else {
                    self.showLastMessage(chatUid: self.existingChats[indexPath.row].uid).then({ messages in
                        chatCell.messageLabel.text = messages.last!.message
                    })
                }
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
    
    @objc func goToChat(row: Int) { }
}
