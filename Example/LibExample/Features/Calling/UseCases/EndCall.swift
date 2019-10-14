//
//  EndCall.swift
//  LibExample
//
//  Created by Manuel on 10/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

class EndCall: UseCase {
    typealias RequestType = Request
    typealias ResponseType = Response
    
    enum Request {
        case stop(Call)
    }
    
    enum Response {
        case callDidStop(Call)
    }
    
    required init(responseHandler: @escaping ((ResponseType) -> ())) {
        self.responseHandler = responseHandler
    }
    
    private let responseHandler: ((Response) -> ())

    func handle(request: Request) {
        switch request {
        case .stop(let call):
            responseHandler(.callDidStop(call))
        }
    }
}
