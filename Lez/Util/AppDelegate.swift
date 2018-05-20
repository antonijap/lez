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

class CustomTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let top: CGFloat = 6
        let bottom: CGFloat = -6
        
        let heart = UIImage(named: "Heart")
        let heartFull = UIImage(named: "Heart_Full")
        let matchViewController = UINavigationController(rootViewController: MatchViewController2())
        matchViewController.tabBarItem = UITabBarItem.init(title: "", image: heart, selectedImage: heartFull)
        matchViewController.tabBarItem.imageInsets = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
        
        
        let chat = UIImage(named: "Chat")
        let chatFull = UIImage(named: "Chat_Full")
        let chatController = UINavigationController(rootViewController: ChatViewController())
        chatController.tabBarItem = UITabBarItem.init(title: "", image: chat, selectedImage: chatFull)
        chatController.tabBarItem.imageInsets = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
        
        let profile = UIImage(named: "Profile")
        let profileFull = UIImage(named: "Profile_Full")
        let profileController = UINavigationController(rootViewController: ProfileViewController())
        profileController.tabBarItem = UITabBarItem.init(title: "", image: profile, selectedImage: profileFull)
        profileController.tabBarItem.imageInsets = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
        
        viewControllers = [matchViewController, chatController, profileController]
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let pushNotifications = PushNotifications.shared
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        FirebaseApp.configure()
        
        UITabBar.appearance().shadowImage = UIImage()
        UITabBar.appearance().backgroundImage = UIImage()
        UITabBar.appearance().tintColor = UIColor(red:0.95, green:0.67, blue:0.24, alpha:1.00)
        UITabBar.appearance().layer.borderColor = UIColor.clear.cgColor
        UITabBar.appearance().layer.borderWidth = 0.0
        UITabBar.appearance().backgroundColor = .white
        
        window = UIWindow(frame: UIScreen.main.bounds)
        if let window = window {
            window.backgroundColor = UIColor.white
            window.rootViewController = CustomTabBarController()
            window.makeKeyAndVisible()
        }
        
        let apiKey = "***REMOVED***"
        GMSPlacesClient.provideAPIKey(apiKey)
        
        TWTRTwitter.sharedInstance().start(withConsumerKey:"jCRNWy0U3EoRpvQHDnMubOhNb", consumerSecret:"G4XulpZ0LRHofdELtUShQLMTENvg2H0jJle22vy8WJx0988HRd")
        
        self.pushNotifications.start(instanceId: "***REMOVED***")
        self.pushNotifications.registerForRemoteNotifications()
        
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        // Deliver content from server, then:
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                // Unlock content
                case .failed, .purchasing, .deferred:
                    break // do nothing
                }
            }
        }
 
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        self.pushNotifications.registerDeviceToken(deviceToken) {
            guard let currentUser = Auth.auth().currentUser else {
                print("There seems to be no auth user.")
                return
            }
            print("OFFICIAL: Subscribed to \(currentUser.uid)")
            try? self.pushNotifications.subscribe(interest: String(currentUser.uid))
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print(userInfo)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return TWTRTwitter.sharedInstance().application(app, open: url, options: options)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

