//
//  SettingsFeature.swift
//  LibExample
//
//  Created by Manuel on 08/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

class SettingsFeature: Feature {
    
    required init(with app: App) {
        self.app = app
    }
    
    weak var app: App?
    
    func handle(feature: Message.Feature) {
        switch feature {
        case .settings(.useCase(let useCase)):
            handle(useCase: useCase)
        default:
            break
        }
    }
    
    private func handle(useCase: Message.Feature.Settings.UseCase) {
        
    }
    
    
}
