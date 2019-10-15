//
//  CreateCallSpec.swift
//  LibExampleTests
//
//  Created by Manuel on 14/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import Quick
import Nimble
@testable import LibExample

class CreateCallSpec: QuickSpec {
    override func spec() {
        describe("the CreateCall UseCase") {
            var sut: CreateCall!
            
            var createdCall: Call!
            
            beforeEach {
                sut = CreateCall {
                    switch $0 {
                    case .callCreated(let call):
                        createdCall = call
                    }
                }
            }
            
            afterEach {
                createdCall = nil
                sut = nil
            }
            
            it("creates call object") {
                sut.handle(request: .createCall)
                
                expect(createdCall).toNot(beNil())
            }
        }
    }
}
