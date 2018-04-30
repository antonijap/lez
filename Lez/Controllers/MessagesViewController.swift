//
//  MessagesViewController.swift
//  Lez
//
//  Created by Antonija on 28/04/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import UIKit
import Firebase

class MessagesViewController: UIViewController {
    
    // Mark: - Properties
    var chatUid: String!
    let textField = UITextField()
    var keyboardHeightLayoutConstraint: NSLayoutConstraint?
    let tableView = UITableView()
    var messages = [Message]()
    var participants: [User] = [User]()
    var myUid: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        myUid = Auth.auth().currentUser?.uid
        
        for participant in participants {
            if participant.uid != myUid {
                navigationItem.title = participant.name
            }
        }
        
        setupTextField()
        setupTableView()
        
        Firestore.firestore().collection("chats").document(chatUid).collection("messages").order(by: "created").addSnapshotListener { (snapshot, error) in
            self.populateMessages()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeKeyboardObserver()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideKeyboardWhenTappedAround()
        addKeyboardChangeFrameObserver(willShow: { [weak self](height) in
            self?.textField.snp.updateConstraints({ (make) in
                make.bottom.equalToSuperview().inset(height)
            })
            self?.view.setNeedsUpdateConstraints()
            }, willHide: { [weak self](height) in
                // Reset constraints here
                self?.textField.snp.updateConstraints({ (make) in
                    make.bottom.equalToSuperview()
                })
                self?.view.setNeedsUpdateConstraints()
        })
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
                    
                } else {
                    print("Will refresh messages")
                    self.messages.removeAll()
                    self.messages = messages
                    self.tableView.reloadData()
                    self.tableView.setNeedsLayout()
                    let indexPath = IndexPath(row: messages.count - 1, section: 0)
                    self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
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
        
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: 48, right: 0)
        tableView.contentInset = insets
        tableView.register(MyMessageCell.self, forCellReuseIdentifier: "MyMessageCell")
        tableView.register(HerMessageCell.self, forCellReuseIdentifier: "HerMessageCell")
    }

    func setupTextField() {
        textField.placeholder = "Say something nice..."
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.borderStyle = UITextBorderStyle.roundedRect
        textField.autocorrectionType = UITextAutocorrectionType.no
        textField.keyboardType = UIKeyboardType.default
        textField.returnKeyType = UIReturnKeyType.done
        textField.clearButtonMode = UITextFieldViewMode.whileEditing
        textField.contentVerticalAlignment = UIControlContentVerticalAlignment.center
        textField.delegate = self
        view.addSubview(textField)
        textField.snp.makeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(48)
        }
        
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
            myCell.timeLabel.text = message.created.dateValue().string(format: .custom("EEE"))
            cell = myCell
        } else {
            // HerCell
            let herCell = tableView.dequeueReusableCell(withIdentifier: HerMessageCell.reuseID) as! HerMessageCell
            herCell.messageLabel.text = message.message
            herCell.timeLabel.text = message.created.dateValue().string(format: .custom("EEE"))
            cell = herCell
        }
        return cell
    }
}


extension MessagesViewController: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        // return NO to disallow editing.
        print("TextField should begin editing method called")
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
        if textField.text != "" {
            if let text = textField.text {
                let data: [String: Any] = [
                    "created": FieldValue.serverTimestamp(),
                    "from": myUid,
                    "message": text
                ]
                FirestoreManager.shared.addNewMessage(to: chatUid, data: data).then { (success) in
                    print("Message added.")
                    self.populateMessages()
                    textField.text = ""
                    textField.resignFirstResponder()
                }
                return true
            }
        }
        return false
    }
    
}
