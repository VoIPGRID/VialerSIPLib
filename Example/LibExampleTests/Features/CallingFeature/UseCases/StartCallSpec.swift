//
//  StartCallSpec.swift
//  LibExampleTests
//
//  Created by Manuel on 14/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import Quick
import Nimble
@testable import LibExample

class StartCallSpec: QuickSpec {
    override func spec() {
        describe("the StartCall UseCase") {
            var sut: StartCall!

            var startedCalls: [Call.State]!
            var failedCalls: [Call.State]!

            beforeEach {
                startedCalls = []
                failedCalls = []

                sut = StartCall(dependencies:self.dependencies) {
                    if case   .callDidStart(let call) = $0 { startedCalls.append(call.state) }
                    if case .failedStarting(let call) = $0 {  failedCalls.append(call.state) }
                }
            }

            afterEach {
                sut = nil
                startedCalls = nil
                failedCalls = nil
            }

            it("calls successfully with valid numbers"){
                ["1236865",
                 "21.7",
                 "217-12",
                 "217   12",
                 "  12121212 ",
                 "+1721998983(9)"
                    ].forEach { sut.handle(request: .startCall(Call(handle: $0), AppState(transportMode:.udp, accountNumber: Keys.SIP.Account, serverAddress: Keys.SIP.Domain))) }

                expect(startedCalls).toEventually(equal([.started, .started, .started, .started, .started, .started]))
            }

            it("fails to call with malformed numbers"){
                ["12QQ45",
                 "",
                 " \n  "
                ].forEach { sut.handle(request: .startCall(Call(handle: $0), AppState(transportMode:.udp, accountNumber: Keys.SIP.Account, serverAddress: Keys.SIP.Domain))) }

                expect(failedCalls).toEventually(equal([.failed, .failed, .failed]))
            }
        }
    }
    
    var dependencies: Dependencies {
        Dependencies(
            currentAppStateFetcher: Mock.CurrentAppStateFetcher(),
                       callStarter: Mock.CallStarter(),
                    statePersister: Mock.StatePersister()
        )
    }
}
