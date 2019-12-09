//
//  RootApp.swift
//  LibExample
//
//  Created by Manuel on 16/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

final
class RootApp: SubscribableApp {
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    private lazy var apps: [App] = [SIPApp(rootMessageHandler: self, dependencies: dependencies)]
    private var receivers: [MessageHandling] { return subscribers + apps}
    private let dependencies: Dependencies

    func handle(msg: Message) {
        receivers.forEach {
            if let msg = dependencies.featureToggler.process(msg: msg) {
                $0.handle(msg: msg)
            }
        }
    }

    private var subscribers: [MessageSubscriber] = []
    func add(subscriber: MessageSubscriber) {
        subscribers.append(subscriber)
    }    
}
