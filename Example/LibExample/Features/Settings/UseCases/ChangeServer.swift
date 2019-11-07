//
//  ChangeServer.swift
//  LibExample
//
//  Created by Manuel on 07/11/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

class ChangeServer: UseCase {
    required init(dependencies: Dependencies, responseHandler: @escaping ((ChangeServer.Response) -> ())) {
        self.dependencies = dependencies
        self.responseHandler = responseHandler
    }
    
    private let dependencies: Dependencies
    private let responseHandler: ((ChangeServer.Response) -> ())
    
    func handle(request: ChangeServer.Request) {
        switch request {
        case .changeAddress(let address):
            responseHandler(.addressChanged(address))
        }
    }
    
    typealias RequestType = Request
    typealias ResponseType = Response
    enum Request {
        case changeAddress(String)
    }
    
    enum Response {
        case addressChanged(String)
    }
}
