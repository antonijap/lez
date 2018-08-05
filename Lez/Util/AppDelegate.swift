//
//  AppDelegate.swift
//  Lez
//
//  Created by Antonija Pek on 20/02/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import UIKit
import GooglePlaces
import Firebase
import FBSDKLoginKit
import TwitterKit
import PushNotifications
import SwiftyStoreKit

final class CustomTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let top: CGFloat = 6
        let bottom: CGFloat = -6

        let heart = #imageLiteral(resourceName: "Heart")
        let heartFull = #imageLiteral(resourceName: "Heart_Full")
        let matchViewController = UINavigationController(rootViewController: MatchViewController())
        matchViewController.tabBarItem = UITabBarItem.init(title: "", image: heart, selectedImage: heartFull)
        matchViewController.tabBarItem.imageInsets = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
        
        
        let chat = #imageLiteral(resourceName: "Chat")
        let chatFull = #imageLiteral(resourceName: "Chat_Full")
        let chatController = UINavigationController(rootViewController: ChatViewController())
        chatController.tabBarItem = UITabBarItem.init(title: "", image: chat, selectedImage: chatFull)
        chatController.tabBarItem.imageInsets = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
        
        let profile = #imageLiteral(resourceName: "Profile")
        let profileFull = #imageLiteral(resourceName: "Profile_Full")
        let profileController = UINavigationController(rootViewController: ProfileViewController())
        profileController.tabBarItem = UITabBarItem.init(title: "", image: profile, selectedImage: profileFull)
        profileController.tabBarItem.imageInsets = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
        
        viewControllers = [matchViewController, chatController, profileController]
    }
}

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let pushNotifications = PushNotifications.shared
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        FirebaseApp.configure()
        
//        prepareWindow()
        
        UITabBar.appearance().shadowImage = UIImage()
        UITabBar.appearance().backgroundImage = UIImage()
        UITabBar.appearance().tintColor = UIColor(red:0.95, green:0.67, blue:0.24, alpha:1.00)
        UITabBar.appearance().layer.borderColor = UIColor.clear.cgColor
        UITabBar.appearance().layer.borderWidth = 0.0
        UITabBar.appearance().backgroundColor = .white
        UIBarButtonItem.appearance().tintColor = .black

        window = UIWindow(frame: UIScreen.main.bounds)
        if let window = window {
            window.backgroundColor = UIColor.white
            window.rootViewController = CustomTabBarController()
            window.makeKeyAndVisible()
        }

        let apiKey = "***REMOVED***"
        GMSPlacesClient.provideAPIKey(apiKey)
        
        TWTRTwitter.sharedInstance().start(withConsumerKey:"***REMOVED***",
                                           consumerSecret:"***REMOVED***")

        pushNotifications.start(instanceId: "***REMOVED***")
        pushNotifications.registerForRemoteNotifications()

        completeIAPTransactions()
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        self.pushNotifications.registerDeviceToken(deviceToken) {
            guard let currentUser = Auth.auth().currentUser else { print("There seems to be no auth user."); return }
            try? self.pushNotifications.subscribe(interest: String(currentUser.uid))
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        let handled = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
        let facebookAuthentication = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String, annotation: options[UIApplicationOpenURLOptionsKey.annotation])
        let twitterAuthentication = TWTRTwitter.sharedInstance().application(app, open: url, options: options)
        return facebookAuthentication || twitterAuthentication || handled
    }
}

extension AppDelegate {
    fileprivate func completeIAPTransactions() {
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                if purchase.transaction.transactionState == .purchased || purchase.transaction.transactionState == .restored {
                    if purchase.needsFinishTransaction { SwiftyStoreKit.finishTransaction(purchase.transaction) }
                }
            }
        }
    }

    /// Checks if the subscription still active
    fileprivate func checkSubscription() {
        if Auth.auth().currentUser != nil { PurchaseManager.verifyPurchase("premium") }
    }
}



// MARK: - Window Management & Navigation
extension AppDelegate {
    private func prepareWindow() {
        window = UIWindow(frame: UIScreen.main.bounds)
//        window?.backgroundColor = .white
        
        guard let _ = Auth.auth().currentUser else {
            
            // What happens when there is no user
            
            displayIntro()
            window?.makeKeyAndVisible()
            
            return
        }
        print("Display Match Room")
        displayPrimaryNavigation()
    }
    
    func displayIntro() {
        window = UIWindow(frame: UIScreen.main.bounds)
        guard let window = window else { return }
        
        let registerViewController = RegisterViewController()
        let navigationController = UINavigationController(rootViewController: registerViewController)
        navigationController.present(navigationController, animated: true, completion: nil)
    }
    
    func displayPrimaryNavigation() {
        guard let window = window else { return }
        window.rootViewController = CustomTabBarController()
        window.backgroundColor = UIColor.white
        window.makeKeyAndVisible()
    }
}
