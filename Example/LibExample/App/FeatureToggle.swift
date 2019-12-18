//
//  FeatureFlag.swift
//  LibExample
//
//  Created by Manuel on 09/12/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import Foundation

enum FeatureFlag: CaseIterable {
    case startCall
    case stopCall
}

struct FeatureFlagModel {
    let featureFlag: FeatureFlag
    let isActivated: Bool
    let title: String
}

protocol FeatureToggling {
    func isActive(flag: FeatureFlag) -> Bool
    func process(msg: Message) -> Message?
    var featureFlagModels: [FeatureFlagModel] { get }
}

class FeatureToggler: FeatureToggling {
    
    fileprivate
    struct FeatureToggle {
        let flag: FeatureFlag
        let isActivated: Bool
        let title: String
        var process: (Message) -> Bool?
    }

    init() {
        featureToggles = [
            .startCall: startCallFeatureToggle(),
             .stopCall:  stopCallFeatureToggle()
        ]
    }

    private let featureToggles: [FeatureFlag: FeatureToggle]
    
    var featureFlagModels: [FeatureFlagModel] {
        return FeatureFlag.allCases.map { (ff) -> FeatureFlagModel in
            return FeatureFlagModel(
                        featureFlag: ff,
                        isActivated: featureToggles[ff]?.isActivated ?? false,
                        title: featureToggles[ff]?.title ?? "\(ff)"
            )
        }
    }
    
    var activatedFlags: [FeatureFlag] {
        let allFlags = FeatureFlag.allCases
        return allFlags.filter { (f) -> Bool in
            guard let toggle = featureToggles[f] else { return false}
            return toggle.isActivated
        }
    }
    
    var deactivatedFlags: [FeatureFlag] {
        let allFlags = FeatureFlag.allCases
        return allFlags.filter { (f) -> Bool in
            guard let toggle = featureToggles[f] else { return true}
            return !toggle.isActivated
        }
    }
    
    func isActive(flag: FeatureFlag) -> Bool {
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

fileprivate func startCallFeatureToggle() -> FeatureToggler.FeatureToggle {
    return FeatureToggler.FeatureToggle(
            flag: .startCall,
            isActivated: true,
            title: "Start Call"
        ) {_ in return nil }
}

fileprivate func stopCallFeatureToggle() -> FeatureToggler.FeatureToggle {
    return FeatureToggler.FeatureToggle(
            flag: .stopCall,
            isActivated: false,
            title: "Stop Call"
    ){ _ in return nil }
}
