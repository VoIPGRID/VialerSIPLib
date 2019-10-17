//
//  StartCall.swift
//  LibExample
//
//  Created by Manuel on 10/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//
import Foundation

// MARK: - UseCase
final
class StartCall: UseCase {
    typealias RequestType = Request
    typealias ResponseType = Response
    
    required init(responseHandler: @escaping ((Response) -> ())) {
        self.responseHandler = responseHandler
    }
    
    private let responseHandler: ((Response) -> ())
    private lazy var interactor = StartCall.Interactor { self.responseHandler($0) }
    
    func handle(request: Request) {
        interactor.handle(request: request)
    }
}

// MARK: - Request & Response
extension StartCall {
    enum Request {
        case startCall(Call)
    }
    
    enum Response {
        case dialing(Call)
        case callDidStart(Call)
        case failedStarting(Call)
    }
}

// MARK: - Interactor
extension StartCall {
    private class Interactor {
        
        init(response: @escaping (StartCall.Response) -> Void) {
            self.response = response
        }

        let response: (StartCall.Response) -> Void

        func handle(request:StartCall.Request) {
            switch request {
            case .startCall(let call):
                response(.dialing(call))
                
                checkHandle(normalise(call.handle))
                ? delay(by: .milliseconds(.random(in: 100..<500))) { self.response(.callDidStart  (transform(call, with: .started))) }
                : delay(by: .milliseconds(.random(in: 100..<200))) { self.response(.failedStarting(transform(call, with:  .failed))) }
            }
        }
    }
}
