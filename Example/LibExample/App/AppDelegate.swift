//
//  AppDelegate.swift
//  LibExample
//
//  Created by Manuel on 08/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    let app = RootApp()
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let navigationController = MessageNavigationController(rootViewController:  CallingViewController())
        let tabBarController = MessageTabBarController()
        
        tabBarController.setViewControllers([navigationController], animated: false)

        tabBarController.responseHandler = app
        app.add(subscriber: tabBarController)
        window = UIWindow(frame: UIScreen.main.bounds)
        
        if let window = window {
            window.rootViewController = tabBarController
            window.makeKeyAndVisible()
        }
        
        return true
    }
}

