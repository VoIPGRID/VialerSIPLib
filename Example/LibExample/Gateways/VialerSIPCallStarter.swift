//
//  File.swift
//  LibExample
//
//  Created by Manuel on 18/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import Foundation


class SIPUser: NSObject, SIPEnabledUser {
    init(sipAccount: String, sipPassword: String, sipDomain: String, proxy: String?) {
        self.sipAccount = sipAccount
        self.sipPassword = sipPassword
        self.sipDomain = sipDomain
        self.sipProxy = proxy
    }
    
    var sipAccount: String
    var sipPassword: String
    var sipDomain: String
    var sipProxy: String?
}

protocol CallManaging {
    func startCall(toNumber: String, for: VSLAccount, completion: @escaping ((VSLCall?, Error?) -> ()))
}

extension VSLCallManager: CallManaging {}

class VialerSIPCallStarter: CallStarting {
    init() {
        
        // If we are CallKit compatible
        if #available(iOS 10.0, *) {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(outboundCallStarted(_:)),
                                                   name: Notification.Name.CallKitProviderDelegateOutboundCallStarted,
                                                   object: nil)
        }
    }
    
    var callback: ((Bool, Call) -> Void)?
    var appState: AppState?
    
    private var vCall: VSLCall?
    private var sipLib : VialerSIPLib?
    private var callManager: VSLCallManager?
    private var account: VSLAccount?
    private var providerDelegate: CallKitProviderDelegate?
    
    @objc func outboundCallStarted(_ notification: NSNotification){
        guard
            let outbounCall = notification.userInfo?[VSLNotificationUserInfoCallKey] as? VSLCall,
            let call = self.call
            else { return }
        vCall = outbounCall
        self.callStarted(call: call)
    }
    
    func start(call: Call) {
        configureForCall(appState: appState!)
        if let account = account {
            account.register { (success, error) in
                success
                    ? self.makeCall(call, account: account)
                    : self.call(call, failed: error!)
            }
        }
    }
    
    private var call: Call?
    private func makeCall(_ call: Call, account: VSLAccount) {
        self.callManager!.startCall(toNumber: call.handle, for: account) { (vCall, error) in
            self.call = call
            if let e = error { // the non-error case will be handled by a notification.
                self.call(call, failed: e)
            }
        }
    }
    
    func call(_ call: Call, failed error:Error ) {
        self.callback?(false,  call)
    }
    
    func callStarted(call: Call) {
        if let provider = providerDelegate?.provider {
            provider.reportOutgoingCall(with: call.uuid, startedConnectingAt: Date())
        }
        self.callback?(true, call)
    }
    
    
    private func configureForCall(appState: AppState) {
        let sipLib = VialerSIPLib.sharedInstance()
        let endPoint =  VSLEndpointConfiguration()
        
        let transportModeMap = [
            TransportMode.udp: VSLTransportType.UDP,
            TransportMode.tcp: VSLTransportType.TCP,
            TransportMode.tls: VSLTransportType.TLS
        ]
        
        let transport = VSLTransportConfiguration(transportType: transportModeMap[appState.transportMode]!)!
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
        
        self.callManager = sipLib.callManager
        providerDelegate = CallKitProviderDelegate(callManager: sipLib.callManager)
        
        let user = SIPUser(
            sipAccount: appState.accountNumber,
            sipPassword: Keys.SIP.Password,
            sipDomain: Keys.SIP.Domain,
            proxy: Keys.SIP.Proxy
        )
        
        do {
            account = try sipLib.createAccount(withSip: user)
        } catch let error {
            print("Could not create account. Error: \(error)")
        }
        
        self.sipLib = sipLib
    }
}
