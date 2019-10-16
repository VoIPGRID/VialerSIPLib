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
            
            var receivedCall: Call!
            
            beforeEach {
                sut = StartCall {
                    let setReceivedCall:(Call) -> Void = { receivedCall = $0}
                    switch $0 {
                    case   .callDidStart(let call): setReceivedCall(call)
                    case .failedStarting(let call): setReceivedCall(call)
                    }
                }
            }
            
            afterEach {
                receivedCall = nil
                sut = nil
            }
            
            it("starts calls successfully with valid numbers"){
                
                let validNumbers = ["1236865", "21.7", "217-12", "217   12", "  12121212 ", "+1721998983"]
                
                var responseStates: [Call.State] = []
                validNumbers.forEach {
                    let newCall = Call(handle: $0)
                    sut.handle(request: .startCall(newCall))
                    
                    responseStates.append(receivedCall!.state)
                }
                expect(responseStates) == [.started, .started, .started, .started, .started, .started]
            }
            
            it("starts calls unsuccessfully with malformed numbers"){
                
                let malformedNumber = ["12QQ45", "", " \n  "]
                var responseStates: [Call.State] = []
                malformedNumber.forEach {
                    let newCall = Call(handle: $0)
                    sut.handle(request: .startCall(newCall))
                    responseStates.append(receivedCall!.state)
                }
                expect(responseStates) == [.failed, .failed, .failed]
            }
        }
    }
}
