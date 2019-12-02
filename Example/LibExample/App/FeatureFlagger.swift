//
//  FeatureFlagger.swift
//  LibExample
//
//  Created by Manuel on 28/11/2019.
//  Copyright © 2019 Harold. All rights reserved.
//


enum FeatureFlag: Hashable {
    case startCall
    case recentListSize(Int)
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .startCall:
            hasher.combine("startCall".hashValue)
        case .recentListSize(let value):
            hasher.combine(value)
        }
    }
}

protocol FeatureFlagging {
    func isEnabled(_ flag:FeatureFlag) -> Bool
}

class FeatureFlagger: FeatureFlagging {
    
    private let flags: [FeatureFlag: Bool] = [
        .startCall: true,
        .recentListSize(10): true
    ]
    
    func isEnabled(_ flag:FeatureFlag) -> Bool {
        return flags[flag] ?? false
    }
}

class MessageInterceptor {
    
    init(featureFlagger: FeatureFlagging) {
        self.featureFlagger = featureFlagger
    }

    let featureFlagger: FeatureFlagging

    func intercept(msg: Message) -> Message? {
        switch msg {
        case .feature(.calling(.useCase(.call(.action(.start(_)))))):
            return featureFlagger.isEnabled(.startCall)
            ?  msg : nil
        default:
            return msg
        }
    }
}
