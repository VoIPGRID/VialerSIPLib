//
//  SIPAppSpec.swift
//  LibExampleTests
//
//  Created by Manuel on 14/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import Quick
import Nimble
@testable import LibExample

class RootAppSpec: QuickSpec {
    override func spec() {
        describe("the RootApp") {
            var sut: RootApp!
            var messageHandler: Mock.MessageHandler!
            var interceptedHandle: String?
            var statePersister: Mock.StatePersister?

            beforeEach {
                statePersister = Mock.StatePersister()
                messageHandler = Mock.MessageHandler {
                    if case .feature(.calling(.useCase(.call(.action(.callDidStart(let call)))))) = $0 { interceptedHandle = call.handle }
                }
                sut = RootApp(dependencies: Dependencies(callStarter: Mock.CallStarter(), statePersister: statePersister))
                sut.add(subscriber: messageHandler)
            }
            
            afterEach {
                statePersister = nil
                sut = nil
                messageHandler = nil
                interceptedHandle = nil
            }
            
            context("Message Passing") {
                it("passes to and receives message from SIPApp"){
                    sut.handle(msg: .feature(.calling(.useCase(.call(.action(.start("2312")))))))
                    
                    expect(interceptedHandle).toEventually(equal("2312"), timeout: 3)
                }
            }
        }
    }
}

