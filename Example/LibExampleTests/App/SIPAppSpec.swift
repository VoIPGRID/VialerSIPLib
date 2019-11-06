//
//  SIPAppSpec.swift
//  LibExampleTests
//
//  Created by Manuel on 16/10/2019.
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
                var receivedCallingActions: [String]!
                var didStartCall: Call!
                var failedCall: Call!
                
                var stopCall: Call!
                var didStopCall: Call!
                var depend: Dependencies!

                beforeEach {
                    receivedCallingActions = []
                    let csf = Mock.CurrentAppStateFetcher()
                    csf.appState = AppState(transportMode: .udp, accountNumber:"4711")
                    depend = Dependencies(callStarter: Mock.CallStarter(), statePersister: Mock.StatePersister(), currentAppStateFetcher: csf)
                    
                    messageHandler = Mock.MessageHandler {
                        if case .feature(.calling(.useCase(.call(.action(let action))))) = $0 {
                            if case .callDidStart(let call) = action { didStartCall = call;  receivedCallingActions.append("didStart") }
                            if case   .callFailed(let call) = action {   failedCall = call;  receivedCallingActions.append(  "failed") }
                            if case         .stop(let call) = action {     stopCall = call;  receivedCallingActions.append(    "stop") }
                            if case  .callDidStop(let call) = action {  didStopCall = call;  receivedCallingActions.append( "didStop") }
                        }
                    }
                    sut = SIPApp(dependencies: depend)
                    sut.add(subscriber: messageHandler)
                }
                
                afterEach {
                    depend = nil
                    sut = nil
                    messageHandler = nil
                    receivedCallingActions = nil
                    didStopCall = nil
                    stopCall = nil
                    didStartCall = nil
                }
                
                it("starts a call with valid number") {
                    sut.handle(msg: .feature(.calling(.useCase(.call(.action(.start("12345")))))))
                    
                    expect(didStartCall).toEventuallyNot(beNil())
                    expect(receivedCallingActions).toEventually(equal(["didStart"]))
                }
                
                it("starts a failing call with malformed number") {
                    sut.handle(msg: .feature(.calling(.useCase(.call(.action(.start("")))))))
                    
                    expect(failedCall).toEventuallyNot(beNil())
                    expect(receivedCallingActions).toEventually(equal(["failed"]))
                }
                
                it("starts a failing call with malformed number") {
                    sut.handle(msg: .feature(.calling(.useCase(.call(.action(.start("QQQ")))))))
                    
                    expect(failedCall).toEventuallyNot(beNil())
                    expect(receivedCallingActions).toEventually(equal(["failed"]))
                }
                
                it("ends a call") {
                    sut.handle(msg: .feature(.calling(.useCase(.call(.action(.stop(transform(Call(handle: "12345"), with: .started) )))))))
                    
                    expect(receivedCallingActions).to(equal(["stop", "didStop"]))
                    expect(stopCall.uuid).to(equal(didStopCall.uuid))
                }
            }
        }
    }
}

