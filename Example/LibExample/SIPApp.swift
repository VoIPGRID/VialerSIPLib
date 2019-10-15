//
//  App.swift
//  LibExample
//
//  Created by Manuel on 08/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

protocol MessageHandling: class {
    func handle(msg: Message)
}

protocol MessageProvider {
    func add(subscriber:MessageSubscriber)
}

protocol MessageSubscriber: MessageHandling { }

protocol App: MessageHandling, MessageProvider { }

class SIPApp: App {
    
    private lazy var features: [Feature] = [
        UserHandlingFeature(with: self),
        SettingsFeature(with: self),
        CallingFeature(with: self)
    ]
    
    func handle(msg: Message) {
        subscribers.forEach { $0.handle(msg: msg) }
        
        switch msg {
        case .feature(let feature):
            features.forEach { $0.handle(feature: feature) }
        }
    }
    
    private var subscribers: [MessageSubscriber] = []
    func add(subscriber: MessageSubscriber) {
        subscribers.append(subscriber)
    }
}
