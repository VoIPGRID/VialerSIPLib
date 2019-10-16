//
//  CreateCall.swift
//  LibExample
//
//  Created by Manuel on 14/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

final
class CreateCall: UseCase {    
    typealias RequestType = Request
    typealias ResponseType = Response
    
    enum Request {
        case createCall(String)
    }
    enum Response {
        case callCreated(Call)
    }
    
    required init(responseHandler: @escaping ((CreateCall.Response) -> ())) {
        self.responseHandler = responseHandler
    }
    private let responseHandler: ((Response) -> ())
    
    func handle(request: CreateCall.Request) {
        switch request {
        case .createCall(let handle):
            responseHandler(.callCreated(Call(handle: handle)))
        }
    }
}
