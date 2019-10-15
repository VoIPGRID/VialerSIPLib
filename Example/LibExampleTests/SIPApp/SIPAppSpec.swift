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


class SIPAppSpec: QuickSpec {
    override func spec() {
        describe("the SIPApp") {
            var sut: SIPApp!
            
            var messageHandler: Mock.MessageHandler!
            
            context("Calling") {
                var receivedCallingActions: [Message.Feature.Calling.UseCase.Calling.Action]!
                var didStartCall: Call!
                var stopCall: Call!
                var didStopCall: Call!
                
                beforeEach {
                    receivedCallingActions = []
                    messageHandler = Mock.MessageHandler {
                        if case .feature(.calling(.useCase(.call(.action(let action))))) = $0 {
                            receivedCallingActions.append(action)
                            if case .callDidStart(let call) = action { didStartCall = call }
                            if case         .stop(let call) = action { stopCall     = call }
                            if case  .callDidStop(let call) = action { didStopCall  = call }
                        }
                    }
                    sut = SIPApp()
                    sut.add(subscriber: messageHandler)
                }
                
                afterEach {
                    sut = nil
                    messageHandler = nil
                    receivedCallingActions = nil
                    didStopCall = nil
                    stopCall = nil
                    didStartCall = nil
                }
                
                
                it("starts a call") {
                    sut.handle(msg: .feature(.calling(.useCase(.call(.action(.start))))))
                    
                    expect(receivedCallingActions).to(equal([.start, .callDidStart(didStartCall)]))
                }
                
                it("ends a call") {
                    sut.handle(msg: .feature(.calling(.useCase(.call(.action(.stop(Call())))))))
                    
                    expect(receivedCallingActions).to(equal([.stop(stopCall), .callDidStop(didStopCall)]))
                }
            }
        }
    }
}
