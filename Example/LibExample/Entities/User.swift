//
//  User.swift
//  LibExample
//
//  Created by Manuel on 08/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

struct User {
    let name:String
}

struct SipUser {
    let sipAccount: String
    let sipPassword: String
    let sipDomain: String
    let sipProxy: String?
    let sipRegisterOnAdd: Bool
    
    init(sipAccount: String, sipPassword: String, sipDomain: String, sipProxy: String?) {
        self.sipAccount = sipAccount
        self.sipPassword = sipPassword
        self.sipDomain = sipDomain
        self.sipProxy = sipProxy
        sipRegisterOnAdd = false
    }

    init() {
        self.init(sipAccount: Keys.SIP.Account, sipPassword: Keys.SIP.Password, sipDomain: Keys.SIP.Domain, sipProxy: Keys.SIP.Proxy.isEmpty ? nil : Keys.SIP.Proxy)
    }
}
