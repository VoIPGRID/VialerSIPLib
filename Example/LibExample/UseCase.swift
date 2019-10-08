//
//  UseCase.swift
//  LibExample
//
//  Created by Manuel on 08/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

protocol UseCase {
    associatedtype RequestType
    associatedtype ResponseType
    
    var reponseHandler: ((ResponseType) -> ())? { get set }
    
    func handle(request: RequestType)
}
