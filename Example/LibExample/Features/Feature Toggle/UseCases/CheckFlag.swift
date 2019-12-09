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
        }
    }
    
    typealias RequestType = Request
    typealias ResponseType = Response
    
    enum Request {
        case isEnabled(Flag)
    }
    
    enum Response {
        case enabled(Flag)
        case disabled(Flag)
    }
    
    required init(dependencies: Dependencies, responseHandler: @escaping ((Response) -> ())) {
        self.dependencies = dependencies
        self.responseHandler = responseHandler
    }
    
    let dependencies: Dependencies
    let responseHandler: (Response) -> ()
}
