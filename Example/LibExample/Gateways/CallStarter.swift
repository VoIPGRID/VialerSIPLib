//
//  File.swift
//  LibExample
//
//  Created by Manuel on 18/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import Foundation


// - (void)startCallToNumber:(NSString * _Nonnull)number forAccount:(VSLAccount * _Nonnull)account completion:(void (^_Nonnull )(VSLCall * _Nullable call, NSError * _Nullable error))completion;


class EnabledUser:NSObject, SIPEnabledUser {
    
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
    init(vialerSipLib: VialerSIPLib) {
        self.sipLib = vialerSipLib
        self.callManager = sipLib.callManager
        providerDelegate = CallKitProviderDelegate(callManager: self.callManager)

        
        let user = EnabledUser(
                         sipAccount: Keys.SIP.Account,
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
    
    
    @objc func outboundCallStarted(_ notification: NSNotification){
        guard
            let _ = notification.userInfo?[VSLNotificationUserInfoCallKey] as? VSLCall,
            let call = self.call
        else { return }
        self.callStarted(call: call)
    }
    
    deinit {
        print("CallStarter deinit")
    }
    
    private let sipLib : VialerSIPLib
    private var account: VSLAccount?
    private var providerDelegate: CallKitProviderDelegate?

    var callback: ((Bool, Call) -> Void)?
    private let callManager: VSLCallManager
    
    func start(call: Call) {
        if let account = account {
            account.register { (success, error) in
                success
                    ? self.makeCall(call, account: account)
                    : self.call(call, failed: error!)
            }
        }
    }
    
//    var vCall: VSLCall?
    var call: Call?
    
    private func makeCall(_ call: Call, account: VSLAccount) {
        self.callManager.startCall(toNumber: call.handle, for: account) { (vCall, error) in
            self.call = call
            if let e = error {
                self.call(call, failed: e)}
            else {
                if let _ = vCall {
                    self.startCall(call: call, account: account)
                }
            }
        }
    }
    
    func startCall(call: Call, account: VSLAccount) {
        self.callManager.startCall(toNumber: call.handle, for: account) { (vCall, error) in
            
            guard vCall != nil else {
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
