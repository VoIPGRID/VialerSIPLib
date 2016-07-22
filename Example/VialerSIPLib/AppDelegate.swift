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

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        DDLogWrapper.setup()
        setupVialerEndpoint()
        return true
    }

    private func setupVialerEndpoint() {
        let endpointConfiguration = VSLEndpointConfiguration()
        endpointConfiguration.userAgent = "VialerSIPLib Example App"
        endpointConfiguration.transportConfigurations = [VSLTransportConfiguration(transportType: .TCP)!, VSLTransportConfiguration(transportType: .UDP)!]
        do {
            try VialerSIPLib.sharedInstance().configureLibraryWithEndPointConfiguration(endpointConfiguration)
            VialerSIPLib.sharedInstance().setIncomingCallBlock{ (call) in
                NSNotificationCenter.defaultCenter().postNotificationName(Configuration.Notifications.IncomingCall, object: call)
            }
        } catch let error {
            DDLogWrapper.logError("Error setting up VialerSIPLib: \(error)")
        }
    }
}