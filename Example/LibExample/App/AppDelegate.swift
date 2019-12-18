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
    
    override init() {        
        let dependencies = createDependencies()
        app = RootApp(dependencies:dependencies)
        app.add(subscriber: dependencies.currentAppStateFetcher)
        super.init()
    }
    
    var window: UIWindow?
    private let app: RootApp
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let callingNavigationController = MessageNavigationController(rootViewController:  MessageViewControllerFactory(kind: .calling).make())
        let settingsNavigationController = MessageNavigationController(rootViewController:  MessageViewControllerFactory(kind: .settings).make())
        let tabBarController = MessageTabBarController()
        
        tabBarController.setViewControllers([callingNavigationController, settingsNavigationController], animated: false)
        tabBarController.tabBar.items?[0].title = "Calling"
        tabBarController.tabBar.items?[1].title = "Settings"
        tabBarController.responseHandler = app
        app.add(subscriber: tabBarController)
        window = UIWindow(frame: UIScreen.main.bounds)
        
        if let window = window {
            window.rootViewController = tabBarController
            window.makeKeyAndVisible()
        }
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        app.handle(msg: .feature(.state(.useCase(.loadInitialState))))
    }
}

private func createDependencies() -> Dependencies {
    return Dependencies(
        currentAppStateFetcher: CurrentAppStateFetcher(),
                   callStarter: VialerSIPCallStarter(),
                statePersister: StateDiskPersister(pathBuilder: PathBuilder(), fileManager: FileManager()),
              ipAddressChecker: IPAddressChecker(),
                featureToggler: FeatureToggler()
    )
}
