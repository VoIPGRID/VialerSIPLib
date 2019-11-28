//
//  FeatureFlagger.swift
//  LibExample
//
//  Created by Manuel on 28/11/2019.
//  Copyright © 2019 Harold. All rights reserved.
//


enum FeatureFlag {
    case startCall
}


class FeatureFlagger {
    
    private let flags = [
        FeatureFlag.startCall: true
    ]
    
    func isEnabled(_ flag:FeatureFlag) -> Bool {
        return flags[flag] ?? true
    }
}

class MessageInterceptor {
    
    init(featureFlagger: FeatureFlagger) {
        self.featureFlagger = featureFlagger
    }
    
    let featureFlagger: FeatureFlagger
    
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
