//
//  RootApp.swift
//  LibExample
//
//  Created by Manuel on 16/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

final
class RootApp: SubscribableApp {
    
    private lazy var apps: [App] = [SIPApp(rootMessageHandler: self, dependencies: dependencies)]
    private var receivers: [MessageHandling] { return subscribers + apps}
    private lazy var dependencies = Dependencies(callStarter: self.callstarter)
    private let callstarter = CallStarter()
    
    func handle(msg: Message) {
        receivers.forEach { $0.handle(msg: msg) }
    }
    
    private var subscribers: [MessageSubscriber] = []
    func add(subscriber: MessageSubscriber) {
        subscribers.append(subscriber)
    }    
}
