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
    func isActive(flag: Flag) -> Bool
    func process(msg: Message) -> Message?
}

class FeatureToggler: FeatureToggling {
    let featureToggles: [Flag: FeatureToggle] = [
        .startCall:
            FeatureToggle(flag: .startCall, isActivated: true) {
                if case .feature(.calling(.useCase(.call(.action(.start(_)))))) = $0 { return true }
                return nil
        }
    ]
    
    func isActive(flag: Flag) -> Bool {
        featureToggles[flag]?.isActivated ?? false
    }
    
    func process(msg: Message) -> Message? {
        for flagAndFeatureToggle in featureToggles {
            let toggle = flagAndFeatureToggle.value
            if
                let processMsg = toggle.process(msg),
                processMsg == true
            {
                return toggle.isActivated ? msg : nil
            }
        }
        return msg
    }
}
