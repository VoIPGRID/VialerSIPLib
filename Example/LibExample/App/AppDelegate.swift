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
        
        let currentAppStateFetcher = CurrentAppStateFetcher()
        app = RootApp(
            dependencies: Dependencies(
                callStarter: CallStarter(vialerSipLib: createSipLib()),
                statePersister: StateDiskPersister(pathBuilder: PathBuilder(), fileManager: FileManager()),
                currentAppStateFetcher:  currentAppStateFetcher
            )
        )
        app.add(subscriber: currentAppStateFetcher)
        super.init()
    }
    
    var window: UIWindow?
    private let app: RootApp
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let navigationController = MessageNavigationController(rootViewController:  CallingViewController())
        let tabBarController = MessageTabBarController()
        
        tabBarController.setViewControllers([navigationController, SettingsViewController()], animated: false)
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

private func createSipLib() -> VialerSIPLib {
    let sipLib = VialerSIPLib.sharedInstance()
    let endPoint =  VSLEndpointConfiguration()
    let transport = VSLTransportConfiguration(transportType: .TLS)!
    endPoint.transportConfigurations = [transport]
    endPoint.userAgent = "VialerSIPLib New Example App"
    endPoint.unregisterAfterCall = false
    
    let ipChhageConf = VSLIpChangeConfiguration()
    ipChhageConf.ipChangeCallsUpdate = .update
    ipChhageConf.ipAddressChangeReinviteFlags = VSLIpChangeConfiguration.defaultReinviteFlags()
    
    endPoint.ipChangeConfiguration = ipChhageConf
    
    let codecConfiguration = VSLCodecConfiguration()
    codecConfiguration.audioCodecs = [
        VSLAudioCodecs(audioCodec: .ILBC, andPriority: 210),
        VSLAudioCodecs(audioCodec: .g711a, andPriority: 209)
    ]
    
    endPoint.codecConfiguration = codecConfiguration
    
    do {
        try sipLib.configureLibrary(withEndPointConfiguration: endPoint)
        
        
    } catch let error {
        print("Error setting up VialerSIPLib: \(error)")
    }
    return sipLib
}
