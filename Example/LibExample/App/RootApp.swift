//
//  RootApp.swift
//  LibExample
//
//  Created by Manuel on 16/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import Foundation

final
class RootApp: SubscribableApp {
    
    private lazy var apps: [App] = [SIPApp(rootMessageHandler: self)]
    
    func handle(msg: Message) {
        subscribers.forEach { $0.handle(msg: msg) }
        apps.forEach { $0.handle(msg:msg) }
    }
    
    private var subscribers: [MessageSubscriber] = []
    func add(subscriber: MessageSubscriber) {
        subscribers.append(subscriber)
    }    
}
