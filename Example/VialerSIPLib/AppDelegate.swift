//
//  AppDelegate.swift
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    struct Configuration {
        struct Notifications {
            static let IncomingCall = "AppDelegate.Notifications.IncomingCall"
        }

    }

    var window: UIWindow?

    // MARK: - Lifecycle

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        DDLogWrapper.setup()
        setupVialerEndpoint()
        return true
    }

    fileprivate func setupVialerEndpoint() {
        let endpointConfiguration = VSLEndpointConfiguration()
        endpointConfiguration.userAgent = "VialerSIPLib Example App"
        endpointConfiguration.transportConfigurations = [VSLTransportConfiguration(transportType: .TCP)!, VSLTransportConfiguration(transportType: .UDP)!]
        do {
            try VialerSIPLib.sharedInstance().configureLibrary(withEndPointConfiguration: endpointConfiguration)
            VialerSIPLib.sharedInstance().setIncomingCall{ (call) in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Configuration.Notifications.IncomingCall), object: call)
            }
        } catch let error {
            DDLogWrapper.logError("Error setting up VialerSIPLib: \(error)")
        }
    }
}
