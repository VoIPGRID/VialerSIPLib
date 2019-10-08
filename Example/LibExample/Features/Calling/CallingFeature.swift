//
//  CallingFeature.swift
//  LibExample
//
//  Created by Manuel on 08/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

class CallingFeature: Feature {
    
    required init(with app: App) {
        self.app = app
    }
    
    private weak var app:App?
    
    func handle(feature: Message.Feature) {
        switch feature {
        case .calling(.useCase(let useCase)):
            handle(useCase: useCase)
        default:
            break
        }
    }
    
    private func handle(useCase: Message.Feature.Calling.UseCase) {
        
    }
    
}
