//
//  LogOut.swift
//  LibExample
//
//  Created by Manuel on 08/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

final
class LogOut: UseCase {
    typealias RequestType = Request
    typealias ResponseType = Response
    
    enum Request {
        case logOut(User)
    }
    
    enum Response {
        case logOutConfirmed(User)
    }
    
    required init(dependencies: Dependencies, responseHandler: @escaping ((Response) -> ())) {
        self.responseHandler = responseHandler
        self.dependencies = dependencies
    }
    
    private let responseHandler: ((Response) -> ())
    private let dependencies: Dependencies

    
    func handle(request: Request) {
        switch request {
        case .logOut(let user):
            responseHandler(.logOutConfirmed(user))
        }
    }
}
