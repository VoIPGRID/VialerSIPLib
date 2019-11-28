//
//  FeatureFlagFeature.swift
//  LibExample
//
//  Created by Manuel on 28/11/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

class FeatureFlagFeature: Feature {
    required init(with rootMessageHandler: MessageHandling, dependencies: Dependencies) {
        self.rootMessageHandler = rootMessageHandler
        self.dependencies = dependencies
    }
    
    let rootMessageHandler: MessageHandling
    let dependencies: Dependencies
    
    func handle(feature: Message.Feature) {
        if case .flag(.isEnbaled(let flag)) = feature {
            dependencies.featureFlagger.isEnabled(flag)
                ? rootMessageHandler.handle(msg: .feature(.flag( .didEnable(flag))))
                : rootMessageHandler.handle(msg: .feature(.flag(.didDisable(flag))))
        }
    }
}
