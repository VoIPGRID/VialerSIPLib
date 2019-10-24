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


struct CallStarter: CallStarting {
    init(vialerSipLib: VialerSIPLib) {
        self.sipLib = vialerSipLib
        self.callManager = sipLib.callManager
    }
    
    
    private let sipLib:VialerSIPLib

    
    var callback: ((Bool, Call) -> Void)?
    private let callManager: VSLCallManager
    
    func start(call: Call) {
        let user = EnabledUser(
                         sipAccount: Keys.SIP.Account,
                        sipPassword: Keys.SIP.Password,
                          sipDomain: Keys.SIP.Domain,
                              proxy: Keys.SIP.Proxy
        )
        
        var account: VSLAccount? = nil
        do {
            account = try sipLib.createAccount(withSip: user)
        } catch let error {
            print("Could not create account. Error: \(error)")
        }
        
        account?.register(completion: { (success, error) in
            if (success) {
                NSLog("Starting call")
                self.startCall(call: call, account: account!)
            } else {
            }
        })

    }
    
    func startCall(call: Call, account: VSLAccount) {
        self.callManager.startCall(toNumber: call.handle, for: account) { (vCall, error) in
            
            guard vCall != nil else {
                NSLog("Call failed " + (error?.localizedDescription ?? "no error"))
                return
            }
            
            NSLog("Got call")
           
        }
    }
    
    func call(_ call: Call, failed error:Error ) {
        self.callback?(false,  call)
    }
    
    func callStarted(call: Call) {
        self.callback?(true, call)
    }
}
