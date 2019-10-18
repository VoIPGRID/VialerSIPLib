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
            
            var startedCalls: [Call]!
            var failedCalls: [Call]!
            var depend: Dependencies!

            beforeEach {
                startedCalls = []
                failedCalls = []
                depend = Dependencies(callStarter: Mock.CallStarter())

                sut = StartCall(dependencies:depend) {
                    switch $0 {
                    case   .callDidStart(let call): startedCalls.append(call)
                    case .failedStarting(let call): failedCalls.append(call)
                    default:
                        break
                    }
                }
            }
            
            afterEach {
                sut = nil
                startedCalls = nil
                failedCalls = nil
                depend = nil
            }
            
            it("calls successfully with valid numbers"){
                
                let validNumbers = ["1236865", "21.7", "217-12", "217   12", "  12121212 ", "+1721998983(9)"]
                validNumbers.forEach {
                    let newCall = Call(handle: $0)
                    sut.handle(request: .startCall(newCall))
                }
                expect(startedCalls.compactMap{ (call) -> Call.State in return call.state })
                    .toEventually(equal([.started, .started, .started, .started, .started, .started]))
            }
            
            it("fails to call with malformed numbers"){
                
                let malformedNumber = ["12QQ45", "", " \n  "]
                malformedNumber.forEach {
                    let newCall = Call(handle: $0)
                    sut.handle(request: .startCall(newCall))
                }
                expect(failedCalls.compactMap{ (call) -> Call.State in return call.state })
                    .toEventually(equal([.failed, .failed, .failed]))
            }
        }
    }
}
