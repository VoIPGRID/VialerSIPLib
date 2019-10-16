//
//  LogIn.swift
//  LibExample
//
//  Created by Manuel on 08/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

final
class LogIn: UseCase {
    typealias RequestType = Request
    typealias ResponseType = Response
    
    enum Request {
        case logIn(String, String)
    }
    
    enum Response {
        case logInConfirmed(User)
    }
    
    required init(responseHandler: @escaping ((Response) -> ())) {
        self.responseHandler = responseHandler
    }
    
    let responseHandler: ((Response) -> ())
    
    func handle(request: Request) {
        switch request {
        case .logIn(let username,_)://(let username, let password):
            responseHandler(.logInConfirmed(User(name: username)))
        }
    }
}
