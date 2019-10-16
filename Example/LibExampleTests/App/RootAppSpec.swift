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
            var interceptedCall: Call!

            beforeEach {
                messageHandler = Mock.MessageHandler {
                    if case .feature(.calling(.useCase(.call(.action(.callDidStart(let call)))))) = $0 { interceptedCall = call }
                }
                sut = RootApp()
                sut.add(subscriber: messageHandler)
            }
            
            afterEach {
                sut = nil
                messageHandler = nil
                interceptedCall = nil
            }
            
            context("Message Passing") {
                it("passes to and receives message from SIPApp"){
                    sut.handle(msg: .feature(.calling(.useCase(.call(.action(.start("2312")))))))
                    
                    expect(interceptedCall.handle) == "2312"
                }
            }
        }
    }
}

