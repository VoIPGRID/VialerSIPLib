//
//  FeatureFlag.swift
//  LibExample
//
//  Created by Manuel on 09/12/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import Foundation

enum Flag {
    case startCall
}

struct FeatureToggle {
    let flag: Flag
    let isActivated: Bool
    var process: (Message) -> Bool?
}


protocol FeatureToggling {
    func isActive(flag:Flag) -> Bool
    func process(msg: Message) -> Message?
}

class FeatureToggler: FeatureToggling {
    let featureFlags: [Flag: FeatureToggle] = [
        .startCall: FeatureToggle(flag: .startCall, isActivated: false) { msg in
            if case .feature(.calling(.useCase(.call(.action(.start(_)))))) = msg { return true }
            return nil
        }
    ]
    
    func isActive(flag:Flag) -> Bool {
        featureFlags[flag]?.isActivated ?? false
    }
    
    func process(msg: Message) -> Message? {
        for x in featureFlags {
            if let b = x.value.process(msg), b == true {
                if x.value.isActivated {
                    return msg
                } else {
                    return nil
                }
            }
        }
        return msg
    }
}
