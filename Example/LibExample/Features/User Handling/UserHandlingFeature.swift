//
//  UserHandlingFeature.swift
//  LibExample
//
//  Created by Manuel on 08/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

final
class UserHandlingFeature: Feature {
    
    required init(with rootMessageHandler: MessageHandling) {
        self.rootMessageHandler = rootMessageHandler
    }
    
    private weak var rootMessageHandler: MessageHandling?
    
    // useCases
    private lazy var logIn  = LogIn()  { [weak self] response in self?.handle(response: response) }
    private lazy var logOut = LogOut() { [weak self] response in self?.handle(response: response) }
    
    func handle(feature: Message.Feature) {
        if case .userHandling(.useCase(let useCase)) = feature {
            handle(useCase: useCase)
        }
    }
    
    private func handle(useCase: Message.Feature.UserHandling.UseCase) {
        if case .login(.action(.logIn(let username, let password))) = useCase {
            logIn.handle(request: .logIn(username, password))
        } else if
            case .logout(.action(.logOut(let user))) = useCase {
            logOut.handle(request: .logOut(user))
        }
    }
    
    private func handle(response: LogIn.Response) {
        switch response {
        case .logInConfirmed(let user):
            rootMessageHandler?.handle(msg:
                .feature(.userHandling(.useCase(.login(.action(.logInConfirmed(user))))))
            )
        }
    }
    
    private func handle(response: LogOut.Response) {
        switch response {
        case .logOutConfirmed(let user):
            rootMessageHandler?.handle(msg:
                .feature(.userHandling(.useCase(.logout(.action(.logOutConfirmed(user))))))
            )
        }
    }
}
