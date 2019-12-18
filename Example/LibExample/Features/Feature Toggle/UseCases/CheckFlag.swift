//
//  CheckFlag.swift
//  LibExample
//
//  Created by Manuel on 09/12/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

class CheckFlag: UseCase {
    func handle(request: Request) {
        switch request {
        case .isEnabled(let flag):
            dependencies.featureToggler.isActive(flag: flag)
                ? responseHandler( .enabled(flag))
                : responseHandler(.disabled(flag))
        case .allEnabledFlags:
            responseHandler(.allFlags(dependencies.featureToggler.featureFlagModels))
        }
    }
    
    typealias RequestType = Request
    typealias ResponseType = Response
    
    enum Request {
        case isEnabled(FeatureFlag)
        case allEnabledFlags
    }
    
    enum Response {
        case enabled(FeatureFlag)
        case disabled(FeatureFlag)
        case allFlags([FeatureFlagModel])
    }
    
    required init(dependencies: Dependencies, responseHandler: @escaping ((Response) -> ())) {
        self.dependencies = dependencies
        self.responseHandler = responseHandler
    }
    
    let dependencies: Dependencies
    let responseHandler: (Response) -> ()
}
