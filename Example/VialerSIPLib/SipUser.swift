//
//  SipUser.swift
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

import Foundation

class SipUser: NSObject, SIPEnabledUser {

    let sipAccount: String
    let sipPassword: String
    let sipDomain: String
    let sipProxy: String
    let sipRegisterOnAdd: Bool

    init(sipAccount: String, sipPassword: String, sipDomain: String, sipProxy: String) {
        self.sipAccount = sipAccount
        self.sipPassword = sipPassword
        self.sipDomain = sipDomain
        self.sipProxy = sipProxy
        sipRegisterOnAdd = false
        super.init()
    }

    convenience override init() {
        self.init(sipAccount: Keys.SIP.Account, sipPassword: Keys.SIP.Password, sipDomain: Keys.SIP.Domain, sipProxy: Keys.SIP.Proxy)
    }
}