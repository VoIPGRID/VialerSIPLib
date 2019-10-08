//
//  LogIn.swift
//  LibExample
//
//  Created by Manuel on 08/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

class LogIn: UseCase {
    
    typealias RequestType = Request
    typealias ResponseType = Response
    
    enum Request {
        case logIn(String, String)
    }
    enum Response {
        case logInConfirmed(User)
    }
    
    var reponseHandler: ((Response) -> ())?
    
    func handle(request: Request) {
        switch request {
        case .logIn(_,_)://(let username, let password):
            reponseHandler?(.logInConfirmed(User()))
        }
    }
}
