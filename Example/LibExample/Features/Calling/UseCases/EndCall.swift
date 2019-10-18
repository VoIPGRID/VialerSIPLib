//
//  EndCall.swift
//  LibExample
//
//  Created by Manuel on 10/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

final
class EndCall: UseCase {
    typealias RequestType = Request
    typealias ResponseType = Response
    
    enum Request {
        case stop(Call)
    }
    
    enum Response {
        case callDidStop(Call)
    }
    
    required init(dependencies: Dependencies, responseHandler: @escaping ((ResponseType) -> ())) {
        self.responseHandler = responseHandler
        self.dependencies = dependencies
    }
    
    private let responseHandler: ((Response) -> ())
    private let dependencies: Dependencies

    func handle(request: Request) {
        switch request {
        case .stop(let call):
            responseHandler(.callDidStop(transform(call, with: .ended)))
        }
    }
}
