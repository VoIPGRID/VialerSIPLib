//
//  UserHandlingFeature.swift
//  LibExample
//
//  Created by Manuel on 08/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

class UserHandlingFeature: Feature {
    
    required init(with app: App) {
        self.app = app
        logIn.reponseHandler = { [weak self] response in self?.handle(response: response) }
        logOut.reponseHandler = { [weak self] response in self?.handle(response: response) }
    }
    
    private weak var app: App?
    
    // useCases
    private let logIn = LogIn()
    private let logOut = LogOut()
    
    func handle(feature: Message.Feature) {
        switch feature {
        case .userHandling(.useCase(let useCase)):
            handle(useCase: useCase)
        default:
            break
        }
    }
    
    private func handle(useCase: Message.Feature.UserHandling.UseCase) {
        switch useCase {
        case .login(.action(.logIn(let username, let password))):
            logIn.handle(request: .logIn(username, password))
        case .logout(.action(.logOut(let user))):
            logOut.handle(request: .logOut(user))
        default:
            break
        }
    }
    
    private func handle(response: LogIn.Response) {
        switch response {
        case .logInConfirmed(let user):
            app?.handle(msg: .feature(.userHandling(.useCase(.login(.action(.logInConfirmed(user)))))))
        }
    }
    
    private func handle(response: LogOut.Response) {
        switch response {
        case .logOutConfirmed(let user):
            app?.handle(msg: .feature(.userHandling(.useCase(.logout(.action(.logOutConfirmed(user)))))))
        }
    }
}
