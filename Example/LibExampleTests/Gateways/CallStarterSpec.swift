//
//  CallStarterSpec.swift
//  LibExampleTests
//
//  Created by Manuel on 18/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import Quick
import Nimble
@testable import LibExample

class CallStarterSpec: QuickSpec {
    override func spec() {
        describe("the CallingStarter Gateway") {
            var sut: CallStarter!
            
            var receivedCall: Call!
            var successfully:Bool = false
            beforeEach {
                sut = CallStarter(callManager: Mock.CallManager(shouldSucceed: true))
                sut.callback = { (success, call) in
                    receivedCall = call
                    successfully = success
                }
            }
            
            afterEach {
                successfully = false
                receivedCall = nil
                sut = nil
            }
            
            it("reports back a successful call"){
                let call = Call(handle: "123(123) 90-9")
                sut.start(call: call)
                
                expect(receivedCall).toEventually(equal(call), timeout: 3)
                expect(successfully).toEventually(beTrue())
            }
            
            it("reports back a unsuccessful call"){
                let call = Call(handle: "123(123) QQQ 90-9")
                sut.start(call: call)
                
                expect(receivedCall).toEventually(equal(call))
                expect(successfully).toEventually(beFalse())
            }
        }
    }
}

