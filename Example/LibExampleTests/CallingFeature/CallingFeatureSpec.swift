//
//  CallingFeatureSpec.swift
//  LibExampleTests
//
//  Created by Manuel on 14/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import Quick
import Nimble
@testable import LibExample

class CallingFeatureSpec: QuickSpec {
    override func spec() {
        describe("the CallingFeature") {
            var sut: CallingFeature!
            
            var messageHandler: Mock.MessageHandler!
            var startedCall: Call!
            var endedCall: Call!
            
            beforeEach {
                messageHandler = Mock.MessageHandler {
                    if case .feature(.calling(.useCase(.call(.action(.callDidStart(let call)))))) = $0 { startedCall = call }
                    if case .feature(.calling(.useCase(.call(.action(.callDidStop (let call)))))) = $0 { endedCall   = call }
                }
                sut = CallingFeature(with: messageHandler)
            }
            
            afterEach {
                startedCall = nil
                endedCall = nil
                messageHandler = nil
                sut = nil
            }
            
            it("creates a call object for started call") {
                sut.handle(feature: .calling(.useCase(.call(.action(.start)))))
                
                expect(startedCall).toNot(beNil())
            }
            
            it("creates a call obect for started call") {
                sut.handle(feature: .calling(.useCase(.call(.action(.start)))))
                sut.handle(feature: .calling(.useCase(.call(.action(.stop(startedCall))))))
                
                expect(endedCall).toNot(beNil())
            }
        }
    }
}
