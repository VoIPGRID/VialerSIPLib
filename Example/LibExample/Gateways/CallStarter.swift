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

class CallStarter: CallStarting {
    var appState: AppState?
    
    init(vialerSipLib: VialerSIPLib) {
        self.sipLib = vialerSipLib
        self.callManager = sipLib.callManager
        providerDelegate = CallKitProviderDelegate(callManager: self.callManager)
        
        let user = SIPUser(
            sipAccount: appState?.accountNumber ?? Keys.SIP.Account,
            sipPassword: Keys.SIP.Password,
            sipDomain: Keys.SIP.Domain,
            proxy: Keys.SIP.Proxy
        )

        do {
            account = try sipLib.createAccount(withSip: user)
        } catch let error {
            print("Could not create account. Error: \(error)")
        }

        // If we are CallKit compatible
        if #available(iOS 10.0, *) {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(outboundCallStarted(_:)),
                                                   name: Notification.Name.CallKitProviderDelegateOutboundCallStarted,
                                                   object: nil)
        }
    }

    var callback: ((Bool, Call) -> Void)?
    private var vCall: VSLCall?
    private let sipLib : VialerSIPLib
    private let callManager: VSLCallManager
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
        self.callManager.startCall(toNumber: call.handle, for: account) { (vCall, error) in
            self.call = call
            if let e = error { // the non-error case will be handled by a notification.
                self.call(call, failed: e)
            }
        }
    }

    func startCall(call: Call, account: VSLAccount) {
        self.callManager.startCall(toNumber: call.handle, for: account) { (vCall, error) in
            
            guard let _ = vCall else  {
                self.call(call, failed: error!)
                return
            }
        }
    }

    func call(_ call: Call, failed error:Error ) {
        self.callback?(false,  call)
    }

    func callStarted(call: Call) {
        self.callback?(true, call)
    }
}
