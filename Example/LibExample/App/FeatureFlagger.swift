//
//  FeatureFlagger.swift
//  LibExample
//
//  Created by Manuel on 28/11/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

enum RecentListSize: Int {
    case none = 0
    case short = 10
    case medium = 20
    case large = 30
    case all = 1000
}

enum FeatureFlag: Hashable {
    case startCall
    case recentListSize(RecentListSize)
    
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
        .recentListSize(.short): true
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
