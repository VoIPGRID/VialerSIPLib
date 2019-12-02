//
//  CheckFlag.swift
//  LibExample
//
//  Created by Manuel on 02/12/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

class CheckFlag: UseCase {
    func handle(request: Request) {
        switch request {
        case .isEnabled(let flag):
            dependencies.featureFlagger.isEnabled(flag)
                ? responseHandler(.enabled(flag))
                : responseHandler(.disabled(flag))
        }
    }
    
    typealias RequestType = Request
    typealias ResponseType = Response
    
    enum Request {
        case isEnabled(FeatureFlag)
    }
    
    enum Response {
        case enabled(FeatureFlag)
        case disabled(FeatureFlag)
    }
    
    required init(dependencies: Dependencies, responseHandler: @escaping ((Response) -> ())) {
        self.dependencies = dependencies
        self.responseHandler = responseHandler
    }
    
    let dependencies: Dependencies
    let responseHandler: (Response) -> ()
}
