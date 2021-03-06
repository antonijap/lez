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
        alertController.addAction(UIAlertAction(title: "Fake Profile", style: .default) { action in
            print("1 is pressed.....")
            self.showOkayModal(messageTitle: "Profile Reported", messageAlert: "We will check this profile as soon as possible.", messageBoxStyle: .alert, alertActionStyle: .default) {
                self.report(type: .fake, reportedUser: user.uid, reportOwner: reportOwner)
            }
        })
        alertController.addAction(UIAlertAction(title: "Not Female", style: .default) { action in
            self.showOkayModal(messageTitle: "Profile Reported", messageAlert: "We will check this profile as soon as possible.", messageBoxStyle: .alert, alertActionStyle: .default) {
                self.report(type: .notFemale, reportedUser: user.uid, reportOwner: reportOwner)
            }
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { action in print("Cancel is pressed......") })

        self.present(alertController, animated: true)
    }

    func report(type: ReportType, reportedUser: String, reportOwner: String) {
        let data: [String: Any] = ["reported": reportedUser,
                                   "reportOwner": reportOwner,
                                   "type": type.rawValue,
                                   "created": FieldValue.serverTimestamp()]
        FirestoreManager.shared.addReport(data: data).then { success in
            if success {
                self.dismiss(animated: true)
            } else {
                self.showOkayModal(messageTitle: "Error happened", messageAlert: "Reporting failed. Please, try again.", messageBoxStyle: .alert, alertActionStyle: .default, completionHandler: {})
            }
        }
    }

    func showBlockActionSheet(currentUser: User, blockedUser: String,  completion: @escaping () -> Void) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let action1 = UIAlertAction(title: "Block User", style: .default) { action in
            self.showOkayModal(messageTitle: "Profile Blocked", messageAlert: "You won't see or hear from this user anymore.", messageBoxStyle: .alert, alertActionStyle: .default, completionHandler: {
                var blockedUsersArray: [String] = currentUser.blockedUsers!
                blockedUsersArray.append(blockedUser)
                let data: [String: Any] = ["blockedUsers": blockedUsersArray]
                FirestoreManager.shared.updateUser(uid: currentUser.uid, data: data).then({ (success) in
                    if success {
                        self.dismiss(animated: true)
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
        
        self.present(alertController, animated: true)
    }
    
    func showPremiumPurchased(completion: @escaping () -> Void) {
        let alert = UIAlertController(title: "Congrats", message: "You are now a Premium user, enjoy unlimited likes.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Okay", style: .default) { _ in completion() }
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    func showSignoutAlert(CTA: String) {
        let alertController = UIAlertController(title: "Are you sure?", message: nil, preferredStyle: .alert)
        let action1 = UIAlertAction(title: "Cancel", style: .default)
        let action2 = UIAlertAction(title: CTA, style: .destructive) { (action) in
            do {
                try Auth.auth().signOut()
                DefaultsManager.shared.saveLoggedInInformation(value: false)
                self.tabBarController?.selectedIndex = 0
                let registerViewController = RegisterViewController()
                let navigationController = UINavigationController(rootViewController: registerViewController)
                self.present(navigationController, animated: false)
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
        present(alert, animated: true)
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

extension Notification.Name {
    static let chatUpdated = Notification.Name("chatUpdated")
}

extension UIView {
    func dropShadow() {
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.3
        self.layer.shadowOffset = CGSize(width: 0, height: 1)
        self.layer.shadowRadius = 2
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
    }
}

extension String {
    
    static func random(length: Int = 20) -> String {
        let base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomString: String = ""
        
        for _ in 0..<length {
            let randomValue = arc4random_uniform(UInt32(base.count))
            randomString += "\(base[base.index(base.startIndex, offsetBy: Int(randomValue))])"
        }
        return randomString
    }
}

extension UIApplication {
    
    class var topViewController: UIViewController? {
        return getTopViewController()
    }
    
    private class func getTopViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return getTopViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return getTopViewController(base: selected)
            }
        }
        if let presented = base?.presentedViewController {
            return getTopViewController(base: presented)
        }
        return base
    }
}

extension Equatable {
    func share() {
        let activity = UIActivityViewController(activityItems: [self], applicationActivities: nil)
        UIApplication.topViewController?.present(activity, animated: true)
    }
}
