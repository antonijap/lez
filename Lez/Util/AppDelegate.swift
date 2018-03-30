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

class CustomTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let loveRoomController = UINavigationController(rootViewController: MatchViewController())
        loveRoomController.tabBarItem = UITabBarItem.init(title: nil, image: UIImage(named: "Heart"), tag: 0)
        loveRoomController.tabBarItem.imageInsets = UIEdgeInsets(top: 9, left: 0, bottom: -9, right: 0)
        
        let chatController = UINavigationController(rootViewController: SetupProfileViewController())
        chatController.tabBarItem = UITabBarItem.init(title: nil, image: UIImage(named: "Chat"), tag: 1)
        chatController.tabBarItem.imageInsets = UIEdgeInsets(top: 9, left: 0, bottom: -9, right: 0)
        
        let profileController = UINavigationController(rootViewController: MatchViewController())
        profileController.tabBarItem = UITabBarItem.init(title: nil, image: UIImage(named: "Profile"), tag: 2)
        profileController.tabBarItem.imageInsets = UIEdgeInsets(top: 9, left: 0, bottom: -9, right: 0)
        
        viewControllers = [loveRoomController, chatController, profileController]
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        FirebaseApp.configure()
        
        UITabBar.appearance().shadowImage = UIImage()
        UITabBar.appearance().backgroundImage = UIImage()
        UITabBar.appearance().tintColor = UIColor(red:0.48, green:0.09, blue:0.68, alpha:1.00)
        UITabBar.appearance().layer.borderColor = UIColor.clear.cgColor
        UITabBar.appearance().layer.borderWidth = 0.0
        
        window = UIWindow(frame: UIScreen.main.bounds)
        if let window = window {
            window.backgroundColor = UIColor.white
            window.rootViewController = CustomTabBarController()
            window.makeKeyAndVisible()
        }
        
        let apiKey = "***REMOVED***"
        GMSPlacesClient.provideAPIKey(apiKey)
        
        return true
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

