//
//  App.swift
//  LibExample
//
//  Created by Manuel on 08/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

protocol MessageHandling {
    func handle(msg: Message)
}

protocol App: class, MessageHandling{
}


class SIPApp: App {
    
    private lazy var features: [Feature] = [
        UserHandlingFeature(with: self),
        SettingsFeature(with: self),
        CallingFeature(with: self)
    ]
    
    func handle(msg: Message) {
        switch msg {
        case .feature(let feature):
            features.forEach {
                $0.handle(feature: feature)
            }
        }
    }
}
