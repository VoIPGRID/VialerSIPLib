//
//  CallSpec.swift
//  LibExampleTests
//
//  Created by Manuel on 15/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import Quick
import Nimble
@testable import LibExample


class CallingActionSpec: QuickSpec {
    override func spec() {
        describe("the Calling Action") {
            var sut: Message.Feature.Calling.UseCase.Calling.Action!
            
            var newCall: Call { return Call(handle: "12345") }
            
            context(".start"){
                beforeEach {
                    sut = .start("12345")
                }
                
                afterEach {
                    sut = nil
                }
                
                it("equals .start"){
                    expect(sut) == .start("12345")
                }
                
                it("doesnt equal .stop"){
                    expect(sut) != .stop(newCall)
                }
                
                it("doesnt equal .callDidStop"){
                    expect(sut) != .callDidStop(newCall)
                }
            }
            
            context(".stop"){
                var call: Call!
                
                beforeEach {
                    call = Call(handle: "12345")
                    sut = .stop(call)
                }
                
                it("doesnt equal .start"){
                    expect(sut) != .start("12345")
                }
                
                it("equals .stop with same call"){
                    expect(sut) == .stop(call)
                }
                
                it("doesnt equal .stop with other call"){
                    expect(sut) != .stop(newCall)
                }
                
                it("doesnt equal .callDidStop"){
                    expect(sut) != .callDidStop(newCall)
                }
            }
        }
    }
}
