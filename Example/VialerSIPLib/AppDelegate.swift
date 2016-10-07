//
//  AppDelegate.swift
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    class var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    struct Configuration {
        struct Notifications {
            static let IncomingCall = "AppDelegate.Notifications.IncomingCall"
        }
    }

    var window: UIWindow?
    var providerDelegate: CallKitProviderDelegate?
    var account: VSLAccount!

    // MARK: - Lifecycle

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        DDLogWrapper.setup()

        if #available(iOS 10.0, *) {
            setupCallKit()
        }

        setupVialerEndpoint()

        do {
            account = try VialerSIPLib.sharedInstance().createAccount(withSip: SipUser())
        } catch let error {
            DDLogWrapper.logError("Could not create account. Error:\(error)\nExiting")
            assert(false)
        }
        return true
    }

    @available(iOS 10.0, *)
    fileprivate func setupCallKit() {
        providerDelegate = CallKitProviderDelegate(callManager: VialerSIPLib.sharedInstance().callManager)
    }

    fileprivate func setupVialerEndpoint() {
        let endpointConfiguration = VSLEndpointConfiguration()
        endpointConfiguration.logLevel = 3
        endpointConfiguration.userAgent = "VialerSIPLib Example App"
        endpointConfiguration.transportConfigurations = [VSLTransportConfiguration(transportType: .TCP)!, VSLTransportConfiguration(transportType: .UDP)!]

        do {
            try VialerSIPLib.sharedInstance().configureLibrary(withEndPointConfiguration: endpointConfiguration)
            // Set your incoming call block here.
            // The code from this block will be called when the framework receives an incoming call.
            VialerSIPLib.sharedInstance().setIncomingCall{ [weak self] (call) in
                self?.displayIncomingCall(call: call)
            }
        } catch let error {
            DDLogWrapper.logError("Error setting up VialerSIPLib: \(error)")
        }
    }

    func displayIncomingCall(call: VSLCall) {
        if #available(iOS 10, *) {
            DDLogWrapper.logInfo("Incoming call block invoked, routing through CallKit.")
            providerDelegate?.reportIncomingCall(call)
        } else {
            DDLogWrapper.logInfo("Incoming call block invoked, using own app presentation.")
            NotificationCenter.default.post(name: Notification.Name(rawValue: Configuration.Notifications.IncomingCall),
                                            object: self,
                                            userInfo: [VSLNotificationUserInfoCallKey : call])
        }
    }

    // MARK: - CallKit outbound call from a iOS native view e.g. Contacts or Recents.
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        if #available(iOS 10.0, *) {
            guard let handle = userActivity.startCallHandle else {
                return false
            }

            VialerSIPLib.sharedInstance().callManager.startCall(toNumber: handle, for:account, completion: { (call, error) in
                if error != nil {
                    DDLogWrapper.logError("Could not create outbound call. Error:\(error)")
                }
            })
        }
        return true
    }
}
