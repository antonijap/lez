//
//  Extensions.swift
//  Lez
//
//  Created by Antonija on 24/03/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Foundation
import UIKit
import Firebase

enum ReportType: String {
    case fake
    case notFemale
}

extension UIViewController: UIActionSheetDelegate {
    func showReportActionSheet(report user: User, reportOwner: String) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let action1 = UIAlertAction(title: "Fake Profile", style: .default) { (action) in
            print("1 is pressed.....")
            self.showOkayModal(messageTitle: "Profile Reported", messageAlert: "We will check this profile as soon as possible.", messageBoxStyle: .alert, alertActionStyle: .default, completionHandler: {
                self.report(type: .fake, reportedUser: user.uid, reportOwner: reportOwner)
            })
        }
        let action2 = UIAlertAction(title: "Not Female", style: .default) { (action) in
            self.showOkayModal(messageTitle: "Profile Reported", messageAlert: "We will check this profile as soon as possible.", messageBoxStyle: .alert, alertActionStyle: .default, completionHandler: {
                self.report(type: .notFemale, reportedUser: user.uid, reportOwner: reportOwner)
            })
        }
        let action3 = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            print("Cancel is pressed......")
        }
        
        alertController.addAction(action1)
        alertController.addAction(action2)
        alertController.addAction(action3)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func report(type: ReportType, reportedUser: String, reportOwner: String) {
        let data: [String: Any] = [
            "reported": reportedUser,
            "reportOwner": reportOwner,
            "type": type.rawValue,
            "created": FieldValue.serverTimestamp()
        ]
        FirestoreManager.shared.addReport(data: data).then { (success) in
            if success {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.showOkayModal(messageTitle: "Error happened", messageAlert: "Reporting failed. Please, try again.", messageBoxStyle: .alert, alertActionStyle: .default, completionHandler: {})
            }
        }
    }
    
    func showBlockActionSheet(currentUser: User, blockedUser: String,  completion: @escaping () -> Void) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let action1 = UIAlertAction(title: "Block User", style: .default) { (action) in
            self.showOkayModal(messageTitle: "Profile Blocked", messageAlert: "You won't see or hear from this user anymore.", messageBoxStyle: .alert, alertActionStyle: .default, completionHandler: {
                
                var blockedUsersArray: [String] = currentUser.blockedUsers!
                blockedUsersArray.append(blockedUser)
                let data: [String: Any] = [
                    "blockedUsers": blockedUsersArray
                ]
                FirestoreManager.shared.updateUser(uid: currentUser.uid, data: data).then({ (success) in
                    if success {
                        self.dismiss(animated: true, completion: nil)
                        completion()
                    } else {
                        self.showOkayModal(messageTitle: "Error happened", messageAlert: "Blocking failed. Please, try again.", messageBoxStyle: .alert, alertActionStyle: .default, completionHandler: {})
                    }
                })
                
            })
        }

        let action2 = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            print("Cancel is pressed......")
        }
        
        alertController.addAction(action1)
        alertController.addAction(action2)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showPremiumPurchased(completion: @escaping () -> Void) {
        let alert = UIAlertController(title: "Congrats", message: "You are now a Premium user, enjoy unlimited likes.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Okay", style: .default) { _ in
            completion()
        }
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    func showSignoutAlert(CTA: String) {
        let alertController = UIAlertController(title: "Are you sure?", message: nil, preferredStyle: .alert)
        let action1 = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        let action2 = UIAlertAction(title: CTA, style: .destructive) { (action) in
            do {
                try Auth.auth().signOut()
                self.tabBarController?.selectedIndex = 0
                let registerViewController = RegisterViewController()
                let navigationController = UINavigationController(rootViewController: registerViewController)
                self.present(navigationController, animated: false, completion: nil)
            } catch let signOutError as NSError {
                print ("Error signing out: %@", signOutError)
            }
        }
        
        alertController.addAction(action1)
        alertController.addAction(action2)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showMatchModal() {
        let alertController = UIAlertController(title: "Match", message: "You have a match. You can continue browsing or go to chat.", preferredStyle: .alert)
        let action1 = UIAlertAction(title: "Continue", style: .default, handler: nil)
        let action2 = UIAlertAction(title: "Go to Chat", style: .default) { (action) in
            self.tabBarController?.selectedIndex = 1
        }
        
        alertController.addAction(action1)
        alertController.addAction(action2)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showOkayModal(messageTitle: String, messageAlert: String, messageBoxStyle: UIAlertControllerStyle, alertActionStyle: UIAlertActionStyle, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: messageTitle, message: messageAlert, preferredStyle: messageBoxStyle)
        
        let okAction = UIAlertAction(title: "Ok", style: alertActionStyle) { _ in
            completionHandler() // This will only get called after okay is tapped in the alert
        }
        
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension Dictionary {
    var json: String {
        let invalidJson = "Not a valid JSON"
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            return String(bytes: jsonData, encoding: String.Encoding.utf8) ?? invalidJson
        } catch {
            return invalidJson
        }
    }
    
    func dict2json() -> String {
        return json
    }
}

extension UIImage {
    // MARK: - UIImage+Resize
    func compressTo(size expectedSizeInMb: Int) -> UIImage? {
        let sizeInBytes = expectedSizeInMb * 1024 * 1024
        var needCompress: Bool = true
        var imgData: Data?
        var compressingValue:CGFloat = 1.0
        while (needCompress && compressingValue > 0.0) {
            if let data:Data = UIImageJPEGRepresentation(self, compressingValue) {
                if data.count < sizeInBytes {
                    needCompress = false
                    imgData = data
                } else {
                    compressingValue -= 0.1
                }
            }
        }
        
        if let data = imgData {
            if (data.count < sizeInBytes) {
                return UIImage(data: data)
            }
        }
        return nil
    }
    
    func resize(percentage: CGFloat) -> UIImage? {
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: size.width * percentage, height: size.height * percentage)))
        imageView.contentMode = .scaleAspectFit
        imageView.image = self
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return result
    }
    func resize(width: CGFloat) -> UIImage? {
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))))
        imageView.contentMode = .scaleAspectFit
        imageView.image = self
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return result
    }
}

extension UIImageView {
    public func makeOvalWithImage(_ anyImage: UIImage) {
        self.contentMode = UIViewContentMode.scaleAspectFill
        self.layer.cornerRadius = 64 / 2
        self.layer.masksToBounds = false
        self.clipsToBounds = true
        
        // make square(* must to make circle),
        // resize(reduce the kilobyte) and
        // fix rotation.
        self.image = anyImage
    }
}

extension Date {
    func toString( dateFormat format  : String ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}

//MARK: - Observers
extension UIViewController {
    
    func addObserverForNotification(_ notificationName: Notification.Name, actionBlock: @escaping (Notification) -> Void) {
        NotificationCenter.default.addObserver(forName: notificationName, object: nil, queue: OperationQueue.main, using: actionBlock)
    }
    
    func removeObserver(_ observer: AnyObject, notificationName: Notification.Name) {
        NotificationCenter.default.removeObserver(observer, name: notificationName, object: nil)
    }
}

//MARK: - Keyboard handling
extension UIViewController {
    
    typealias KeyboardHeightClosure = (CGFloat) -> ()
    
    func addKeyboardChangeFrameObserver(willShow willShowClosure: KeyboardHeightClosure?,
                                        willHide willHideClosure: KeyboardHeightClosure?) {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillChangeFrame,
                                               object: nil, queue: OperationQueue.main, using: { [weak self](notification) in
                                                if let userInfo = notification.userInfo,
                                                    let frame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
                                                    let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? Double,
                                                    let c = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? UInt,
                                                    let kFrame = self?.view.convert(frame, from: nil),
                                                    let kBounds = self?.view.bounds {
                                                    
                                                    let animationType = UIViewAnimationOptions(rawValue: c)
                                                    let kHeight = kFrame.size.height
                                                    UIView.animate(withDuration: duration, delay: 0, options: animationType, animations: {
                                                        if kBounds.intersects(kFrame) { // keyboard will be shown
                                                            willShowClosure?(kHeight)
                                                        } else { // keyboard will be hidden
                                                            willHideClosure?(kHeight)
                                                        }
                                                    }, completion: nil)
                                                } else {
                                                    print("Invalid conditions for UIKeyboardWillChangeFrameNotification")
                                                }
        })
    }
    
    func removeKeyboardObserver() {
        removeObserver(self, notificationName: NSNotification.Name.UIKeyboardWillChangeFrame)
    }
}

extension Notification.Name {
    static let chatUpdated = Notification.Name("chatUpdated")
}
