//
//  MessagesViewController.swift
//  Lez
//
//  Created by Antonija on 28/04/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import UIKit
import Firebase
import Alertift
import SwiftyJSON
import SwiftDate
import Alamofire
import Spring

class MessagesViewController: UIViewController {
    
    // Mark: - Properties
    var chatUid: String!
    var participants: [User] = [User]()
    private let textField = UITextField()
    private var bottomConstraint = KeyboardLayoutConstraint()
    private let tableView = UITableView()
    private var messages = [Message]()
    private var myUid: String!
    private var textFieldContainer = UIView()
    private var sendButton = UIButton()
    private var topBorderView = UIView()
    private var herUid: String!
    private var name: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        myUid = Auth.auth().currentUser?.uid
        
        for participant in participants {
            if participant.uid != myUid {
                herUid = participant.uid
                navigationItem.title = participant.name
                let filterButton = UIButton(type: .custom)
                filterButton.setImage(UIImage(named: "Dots"), for: .normal)
                filterButton.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
                filterButton.addTarget(self, action: #selector(self.menuTapped), for: .touchUpInside)
                let rightItem = UIBarButtonItem(customView: filterButton)
                navigationItem.setRightBarButtonItems([rightItem], animated: true)
            } else {
                name = participant.name
            }
        }
        
        setupTextField()
        setupTableView()
        
        // Slusaj izmjene u chatu (sluzi da vidim ako postane disabled)
        let ref = Firestore.firestore().collection("chats").document(chatUid)
        ref.addSnapshotListener { (document, error) in
            if let document = document {
                FirestoreManager.shared.parseFirebaseChat(document: document).then({ (chat) in
                    guard let data = document.data() else { return }
                    guard let isDisabled = data["isDisabled"] as? Bool else {
                        print("Problem with parsing isDisabled.")
                        return
                    }
                    
                    if isDisabled {
                        self.textFieldContainer.isHidden = true
                    } else {
                        self.textFieldContainer.isHidden = false
                        Firestore.firestore().collection("chats").document(self.chatUid).collection("messages").order(by: "created").addSnapshotListener { (snapshot, error) in
                            self.populateMessages()
                        }
                    }
                })
            } else {
                print("Document does not exist")
            }
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeKeyboardObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideKeyboardWhenTappedAround()
        addKeyboardObservers()
    }

    func addKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: self.textFieldContainer)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: self.textFieldContainer)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        let keyboardHeight = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.height
        UIView.animate(withDuration: 1.1, animations: { () -> Void in
            self.textFieldContainer.snp.updateConstraints({ (make) in
                make.bottom.equalTo(-1 * keyboardHeight!)
            })
            self.textFieldContainer.superview?.layoutIfNeeded()
        })
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            self.textFieldContainer.snp.updateConstraints({ (make) in
                make.bottom.equalToSuperview()
            })
            self.textFieldContainer.superview?.layoutIfNeeded()
        })
    }
    
    @objc private func menuTapped() {
        Alertift.actionSheet(message: "Manage Chat")
            .actions(["Block and Delete"])
            .action(.cancel("Cancel"))
            .finally { action, index in
                if action.style == .cancel {
                    return
                }
                if index == 0 {
                    Alertift.alert(message: "Blocked")
                        .action(.default("Okay"), handler: { (_, _, _) in
                            // Flag chat as isDisabled
                            Firestore.firestore().collection("chats").document(self.chatUid).updateData(["isDisabled": true], completion: { (error) in
                                if let error = error {
                                    print(error.localizedDescription)
                                }
                                // Now update user values
                                FirestoreManager.shared.fetchUser(uid: self.myUid).then({ (user) in
                                    var blockedUsersArray: [String] = user.blockedUsers!
                                    blockedUsersArray.append(self.herUid)
                                    var chats: [String] = []
                                    
                                    // Remove blocked users
                                    for chat in user.chats! {
                                        if user.chats?.contains(self.chatUid) != true {
                                            chats.append(chat)
                                        }
                                    }
                                    
                                    let data: [String: Any] = [
                                        "blockedUsers": blockedUsersArray,
                                        "chats": chats
                                    ]
                                    
                                    FirestoreManager.shared.updateUser(uid: user.uid, data: data).then({ (success) in
                                        if success {
                                            self.navigationController?.popToRootViewController(animated: true)
                                        } else {
                                            self.showOkayModal(messageTitle: "Error happened", messageAlert: "Blocking failed. Please, try again.", messageBoxStyle: .alert, alertActionStyle: .default, completionHandler: {})
                                        }
                                    })
                                })
                            })
                            
                        })
                        .show()
                }
            }
            .show(on: self, completion: nil)
    }
    
    func populateMessages() {
        var messages = [Message]()
        let group = DispatchGroup()
        let docRef = Firestore.firestore().collection("chats").document(chatUid).collection("messages").order(by: "created")
        docRef.getDocuments { (snapshot, error) in
            guard let document = snapshot else {
                print("Error fetching document: \(error!)")
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
                if messages.isEmpty {
                    print("Nema poruka")
                } else {
                    if messages.count > 20 {
                        self.messages.removeAll()
                        self.messages = messages
                        self.tableView.reloadData()
                        self.tableView.setNeedsLayout()
                        let indexPath = IndexPath(row: messages.count - 1, section: 0)
                        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                    } else {
                        self.messages.removeAll()
                        self.messages = messages
                        self.tableView.reloadData()
                        self.tableView.setNeedsLayout()
                    }
                }
            })
        }
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
            make.bottom.equalTo(textField.snp.top)
        }
        tableView.backgroundColor = .white
        tableView.separatorColor = .clear
        tableView.isUserInteractionEnabled = true
        
        let insets = UIEdgeInsets(top: 16, left: 0, bottom: 48, right: 0)
        tableView.contentInset = insets
        tableView.register(MyMessageCell.self, forCellReuseIdentifier: "MyMessageCell")
        tableView.register(HerMessageCell.self, forCellReuseIdentifier: "HerMessageCell")
    }

    func setupTextField() {
        view.addSubview(textFieldContainer)
        textFieldContainer.snp.makeConstraints { (make) in
            make.height.equalTo(50)
            make.width.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        textFieldContainer.addSubview(sendButton)
        sendButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(60)
        }
        sendButton.setTitle("Send", for: .normal)
        sendButton.addTarget(self, action: #selector(self.sendMessage), for: .touchUpInside)
        sendButton.setTitleColor(UIColor(red:0.95, green:0.67, blue:0.24, alpha:1.00), for: .normal)
        
        textField.placeholder = "Say something nice..."
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.autocorrectionType = UITextAutocorrectionType.no
        textField.keyboardType = UIKeyboardType.default
        textField.returnKeyType = UIReturnKeyType.done
        textField.clearButtonMode = UITextFieldViewMode.whileEditing
        textField.contentVerticalAlignment = UIControlContentVerticalAlignment.center
        textField.delegate = self
        textFieldContainer.addSubview(textField)
        textField.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.right.equalTo(sendButton.snp.left).inset(8)
        }
        
        textFieldContainer.addSubview(topBorderView)
        topBorderView.snp.makeConstraints { (make) in
            make.height.equalTo(1)
            make.width.equalToSuperview()
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        topBorderView.backgroundColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:0.5)
        
    }
}
extension MessagesViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        let message = messages[indexPath.row]
        if message.from == myUid {
            // MyCell
            let myCell = tableView.dequeueReusableCell(withIdentifier: MyMessageCell.reuseID) as! MyMessageCell
            myCell.messageLabel.text = message.message
            let date = message.created.date(format: .custom("yyyy-MM-dd HH:mm:ss"))
            myCell.timeLabel.text = "\(String(describing: date!.string(custom: "MMM dd"))) at \(String(describing: date!.string(custom: "HH:mm")))"
            cell = myCell
        } else {
            // HerCell
            let herCell = tableView.dequeueReusableCell(withIdentifier: HerMessageCell.reuseID) as! HerMessageCell
            herCell.messageLabel.text = message.message
            let date = message.created.date(format: .custom("yyyy-MM-dd HH:mm:ss"))
            herCell.timeLabel.text = "\(String(describing: date!.string(custom: "MMM dd"))) at \(String(describing: date!.string(custom: "HH:mm")))"
            cell = herCell
        }
        return cell
    }
    
    @objc func sendMessage() {
        if textField.text != "" {
            if let text = textField.text {
                print(text)
                let data: [String: Any] = [
                    "created": Date().toString(dateFormat: "yyyy-MM-dd HH:mm:ss"),
                    "from": myUid,
                    "message": text
                ]
                FirestoreManager.shared.addNewMessage(to: chatUid, data: data).then { (success) in
                    self.textField.text = ""
                    let parameters: Parameters = ["channel": self.herUid!, "event": Events.newMessage.rawValue, "message": "\(self.name!) sent message"]
                    Alamofire.request("https://us-central1-lesbian-dating-app.cloudfunctions.net/triggerPusherChannel", method: .post, parameters: parameters, encoding: URLEncoding.default)
//                    self.textField.resignFirstResponder()
                    self.populateMessages()
                }
            }
        }
    }
}


extension MessagesViewController: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        // return NO to disallow editing.
//        print("TextField should begin editing method called")
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // became first responder
//        print("TextField did begin editing method called")
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        // return YES to allow editing to stop and to resign first responder status. NO to disallow the editing session to end
//        print("TextField should snd editing method called")
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // may be called if forced even if shouldEndEditing returns NO (e.g. view removed from window) or endEditing:YES called
//        print("TextField did end editing method called")
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        // if implemented, called in place of textFieldDidEndEditing:
//        print("TextField did end editing with reason method called")
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // return NO to not change text
//        print("While entering the characters this method gets called")
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        // called when clear button pressed. return NO to ignore (no notifications)
//        print("TextField should clear method called")
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // called when 'return' key pressed. return NO to ignore.
//        print("TextField should return method called")
        sendMessage()
        return false
    }
    
}
