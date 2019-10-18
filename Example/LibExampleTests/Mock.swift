//
//  Mock.swift
//  LibExampleTests
//
//  Created by Manuel on 15/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//
import Foundation
@testable import LibExample

class Mock {
    class MessageHandler: MessageHandling, MessageSubscriber {
        
        init(callBack: @escaping (Message) -> ()) {
            self.callBack = callBack
        }
        
        let callBack: (Message) -> ()
        
        func handle(msg: Message) { callBack(msg) }
    }
    
    struct CallStarter: CallStarting {
        init() {}
        
        var deferResponse: ((Bool) -> DispatchTimeInterval) = {
            switch $0 {
            case true: return .milliseconds(10)
            case false: return .milliseconds(7)
            }
        }

        var callback: ((Bool, Call) -> Void)?
        func start(call: Call) {
            checkHandle(call.handle)
                ? delay(by: deferResponse( true)) { self.callback?( true, call)}
                : delay(by: deferResponse(false)) { self.callback?(false, call)}
        }
    }
}
