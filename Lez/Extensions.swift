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
            self.showOkayModal(messageTitle: "Profile Reported", messageAlert: "We will check this profile as soon as possible", messageBoxStyle: .alert, alertActionStyle: .default, completionHandler: {
                // Send message to backend
            })
        }
        let action2 = UIAlertAction(title: "Not Female", style: .default) { (action) in
            self.showOkayModal(messageTitle: "Profile Reported", messageAlert: "We will check this profile as soon as possible", messageBoxStyle: .alert, alertActionStyle: .default, completionHandler: {
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
    
    func showOkayModal(messageTitle: String, messageAlert: String, messageBoxStyle: UIAlertControllerStyle, alertActionStyle: UIAlertActionStyle, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: messageTitle, message: messageAlert, preferredStyle: messageBoxStyle)
        
        let okAction = UIAlertAction(title: "Ok", style: alertActionStyle) { _ in
            completionHandler() // This will only get called after okay is tapped in the alert
        }
        
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
}

