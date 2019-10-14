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
                    switch $0 {
                    case .callDidStart(let call):
                        receivedCall = call
                    }
                }
            }
            
            afterEach {
                receivedCall = nil
                sut = nil
            }
            
            it("creates a call object for new call"){
                sut.handle(request: .startCall(Call()))
                
                expect(receivedCall).toNot(beNil())
            }
        }
    }
}
