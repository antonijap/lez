//
//  Extensions.swift
//  Lez
//
//  Created by Antonija on 24/03/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController: UIActionSheetDelegate {
    func showReportActionSheet() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let action1 = UIAlertAction(title: "Fake Profile", style: .default) { (action) in
            print("1 is pressed.....")
            self.showOkayModal(messageTitle: "Profile Reported", messageAlert: "We will check this profile as soon as possible.", messageBoxStyle: .alert, alertActionStyle: .default, completionHandler: {
                // Send message to backend
            })
        }
        let action2 = UIAlertAction(title: "Not Female", style: .default) { (action) in
            self.showOkayModal(messageTitle: "Profile Reported", messageAlert: "We will check this profile as soon as possible.", messageBoxStyle: .alert, alertActionStyle: .default, completionHandler: {
                // Send message to backend
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
    
    func showBlockActionSheet() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let action1 = UIAlertAction(title: "Block Profile", style: .default) { (action) in
            print("1 is pressed.....")
            self.showOkayModal(messageTitle: "Profile Blocked", messageAlert: "You won't see or hear from this user anymore.", messageBoxStyle: .alert, alertActionStyle: .default, completionHandler: {
                // Send message to backend
            })
        }

        let action2 = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            print("Cancel is pressed......")
        }
        
        alertController.addAction(action1)
        alertController.addAction(action2)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showSignoutAlert(CTA: String) {
        let alertController = UIAlertController(title: "Are you sure?", message: nil, preferredStyle: .alert)

        let action1 = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        
        let action2 = UIAlertAction(title: CTA, style: .destructive) { (action) in
            print("Signout")
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

// Put this piece of code anywhere you like
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
