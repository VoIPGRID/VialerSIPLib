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

protocol ResponseHandling {
    var responseHandler: MessageHandling? { get set }
}

protocol MessageProvider {
    func add(subscriber:MessageSubscriber)
}

protocol MessageSubscriber: MessageHandling { }

protocol App: MessageHandling { }

protocol SubscribableApp: App, MessageProvider {}

final
class SIPApp: SubscribableApp {
    
    init(rootMessageHandler: MessageHandling? = nil, dependencies: Dependencies) {
        self.privateRootMessageHandler = rootMessageHandler
        self.dependencies = dependencies
    }
    
    var rootMessageHandler: MessageHandling { return privateRootMessageHandler ?? self }
    private let privateRootMessageHandler: MessageHandling?
    private let dependencies: Dependencies
    
    private lazy var features: [Feature] = [
        UserHandlingFeature(with: rootMessageHandler, dependencies: dependencies),
        SettingsFeature(with: rootMessageHandler, dependencies: dependencies),
        CallingFeature(with: rootMessageHandler, dependencies: dependencies),
        StateKeeperFeature(with: rootMessageHandler, dependencies: dependencies)
    ]
    
    func handle(msg: Message) {
        subscribers.forEach { $0.handle(msg: msg) }
        
        if case .feature(let feature) = msg {
            features.forEach { $0.handle(feature: feature) }
        }
    }
    
    private var subscribers: [MessageSubscriber] = []
    func add(subscriber: MessageSubscriber) {
        subscribers.append(subscriber)
    }
}
