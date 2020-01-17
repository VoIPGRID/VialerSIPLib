//
//  AppDelegate.swift
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    struct Configuration {
        struct Notifications {
            static let incomingCall = Notification.Name("AppDelegate.Notification.IncomingCall")
        }
    }

    static var shared: AppDelegate!

    var window: UIWindow?
    var providerDelegate: CallKitProviderDelegate?
    var account: VSLAccount!

    override init() {
        super.init()
        AppDelegate.shared = self
    }

    // MARK: - Lifecycle

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        DDLogWrapper.setup()
        setupCallKit()
        setupLogCallBack()
        setupVoIPEndpoint()
        setupAccount()
        return true
    }

    fileprivate func setupCallKit() {
        providerDelegate = CallKitProviderDelegate(callManager: VialerSIPLib.sharedInstance().callManager)
    }

    func setupVoIPEndpoint() {
        let prefs = UserDefaults.standard
        let transportType = prefs.string(forKey: "transportType")
        var transportToUse: [VSLTransportConfiguration] {
            switch transportType {
            case "TLS"?:
                DDLogWrapper.logInfo("Using TLS");
                return [VSLTransportConfiguration(transportType: .TLS)!]
            case "TCP"?:
                DDLogWrapper.logInfo("Using TCP");
                return [VSLTransportConfiguration(transportType: .TCP)!]
            default:
                DDLogWrapper.logInfo("Using UDP");
                return [VSLTransportConfiguration(transportType: .UDP)!]
            }
        }

        let endpointConfiguration = VSLEndpointConfiguration()
        endpointConfiguration.userAgent = "VialerSIPLib Example App"
        endpointConfiguration.transportConfigurations = transportToUse
        endpointConfiguration.disableVideoSupport = !prefs.bool(forKey: "useVideo")
        endpointConfiguration.unregisterAfterCall = prefs.bool(forKey: "unregisterAfterCall")

        let ipChangeConfiguration = VSLIpChangeConfiguration()
        ipChangeConfiguration.ipChangeCallsUpdate = .update
        ipChangeConfiguration.ipAddressChangeReinviteFlags = VSLIpChangeConfiguration.defaultReinviteFlags()

        endpointConfiguration.ipChangeConfiguration = ipChangeConfiguration;

        let codecConfiguration = VSLCodecConfiguration()
        codecConfiguration.audioCodecs = [
            VSLAudioCodecs(audioCodec: .ILBC, andPriority: 210),
            VSLAudioCodecs(audioCodec: .g711a, andPriority: 209)
        ]
        // TODO: Remove the below if not needed.
//        codecConfiguration.videoCodecs = [
//            VSLVideoCodecs(videoCodec: .H264, andPriority: 210)
//        ]
        endpointConfiguration.codecConfiguration = codecConfiguration;

        do {
            try VialerSIPLib.sharedInstance().configureLibrary(withEndPointConfiguration: endpointConfiguration)
            // Set your incoming call block here.
            setupIncomingCallBlock()
        } catch let error {
            DDLogWrapper.logError("Error setting up VialerSIPLib: \(error)")
        }
    }

    func stopVoIPEndPoint() {
        VialerSIPLib.sharedInstance().removeEndpoint()
    }

    func setupAccount() {
        do {
            account = try VialerSIPLib.sharedInstance().createAccount(withSip: SipUser())
        } catch let error {
            DDLogWrapper.logError("Could not create account. Error:\(error)\nExiting")
            assert(false)
        }
    }

    func getAccount() -> VSLAccount! {
        return account
    }
    
    func setupIncomingCallBlock() {
        // The code from this block will be called when the framework receives an incoming call.
        VialerSIPLib.sharedInstance().setIncomingCall{ [weak self] (call) in
            DispatchQueue.main.async {
                self?.displayIncomingCall(call: call)
            }
        }
    }
    
    func setupLogCallBack() {
        VialerSIPLib.sharedInstance().setLogCallBack { (logMessage) in
            DDLogWrapper.log(message: logMessage)
        }
    }

    func displayIncomingCall(call: VSLCall) {
        DDLogWrapper.logInfo("Incoming call block invoked, routing through CallKit.")
        providerDelegate?.reportIncomingCall(call)
    }

    // MARK: - CallKit outbound call from a iOS native view e.g. Contacts or Recents.
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        guard let handle = userActivity.startCallHandle else {
            return false
        }
        VialerSIPLib.sharedInstance().callManager.startCall(toNumber: handle, for:account, completion: { (call, error) in
            if error != nil {
                DDLogWrapper.logError("Could not create outbound call. Error: \(error!)")
            }
            // TODO: Investigate the need of returning false in case of error here.
        })
        return true
    }
}
