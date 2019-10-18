//
//  SwitchTransportMode.swift
//  LibExample
//
//  Created by Manuel on 10/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

class SwitchTransportMode: UseCase {
    typealias RequestType = Request
    typealias ResponseType = Response
    
    enum Request {
        case setMode(TransportOption)
    }
    
    enum Response {
        case modeWasActivated(TransportOption)
    }
    
    required init(dependencies: Dependencies, responseHandler: @escaping ((ResponseType) -> ())) {
        self.responseHandler = responseHandler
        self.dependencies = dependencies
    }
    
    private let responseHandler: ((Response) -> ())
    private let dependencies: Dependencies

    func handle(request: Request) {
        switch request {
        case .setMode(let option):
            responseHandler(.modeWasActivated(option))
        }
    }
}
