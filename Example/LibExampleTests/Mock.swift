//
//  Mock.swift
//  LibExampleTests
//
//  Created by Manuel on 15/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

@testable import LibExample

class Mock {
    class MessageHandler: MessageHandling, MessageSubscriber {
        
        init(callBack: @escaping (Message) -> ()) {
            self.callBack = callBack
        }
        
        let callBack: (Message) -> ()
        
        func handle(msg: Message) {
            callBack(msg)
        }
    }
}
