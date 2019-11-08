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
            var endedCall: Call!
            var depend: Dependencies!

            beforeEach {
                depend = Dependencies(callStarter: Mock.CallStarter(), statePersister: Mock.StatePersister(), currentAppStateFetcher: CurrentAppStateFetcher())
                
                depend.callStarter.appState = AppState(transportMode: .udp, accountNumber: "0815", serverAddress: "server")
                messageHandler = Mock.MessageHandler {
                    if case .feature(.calling(.useCase(.call(.action(.callDidStop (let call)))))) = $0 { endedCall   = call }
                }
                sut = CallingFeature(with: messageHandler, dependencies:depend)
            }
            
            afterEach {
                endedCall = nil
                messageHandler = nil
                sut = nil
            }

            it("end call") {
                sut.handle(feature: .calling(.useCase(.call(.action(.stop(transform(Call(handle:"4567"), with: .started)))))))
                
                expect(endedCall).toNot(beNil())
            }
        }
    }
}
