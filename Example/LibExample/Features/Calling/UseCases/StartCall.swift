//
//  StartCall.swift
//  LibExample
//
//  Created by Manuel on 10/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

class StartCall: UseCase {
    typealias RequestType = Request
    typealias ResponseType = Response
    
    enum Request {
        case startCall
    }
    
    enum Response {
        case callDidStart(Call)
    }
    
    required init(responseHandler: @escaping ((Response) -> ())) {
        self.responseHandler = responseHandler
    }
    
    private let responseHandler: ((Response) -> ())

    func handle(request: Request) {
        responseHandler(.callDidStart(Call()))
    }
}
