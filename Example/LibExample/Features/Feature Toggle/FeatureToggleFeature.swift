//
//  FeatureToggleFeature.swift
//  LibExample
//
//  Created by Manuel on 09/12/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

class FeatureFlagFeature: Feature {
    required init(with rootMessageHandler: MessageHandling, dependencies: Dependencies) {
        self.rootMessageHandler = rootMessageHandler
        self.dependencies = dependencies
    }
    
    private let rootMessageHandler: MessageHandling
    private let dependencies: Dependencies
    
    private lazy var checkFlag = CheckFlag(dependencies: self.dependencies) { self.handle(response: $0) }
    
    func handle(feature: Message.Feature) {
        if case .flag(.useCase(.isEnbaled(let flag))) = feature {
            checkFlag.handle(request: .isEnabled(flag))
        }
    }
    
    private func handle(response: CheckFlag.Response) {
        switch response {
        case  .enabled(let flag): rootMessageHandler.handle(msg: .feature(.flag(.useCase( .didEnable(flag)))))
        case .disabled(let flag): rootMessageHandler.handle(msg: .feature(.flag(.useCase(.didDisable(flag)))))
        }
    }
}
