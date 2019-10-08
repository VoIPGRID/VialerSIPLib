//
//  LogOut.swift
//  LibExample
//
//  Created by Manuel on 08/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

class LogOut: UseCase {
    
    typealias RequestType = Request
    typealias ResponseType = Response
    
    enum Request {
        case logOut(User)
    }
    enum Response {
        case logOutConfirmed(User)
    }
    
    var reponseHandler: ((Response) -> ())?
    
    func handle(request: Request) {
        switch request {
        case .logOut(let user):
            reponseHandler?(.logOutConfirmed(user))
        }
    }
}
