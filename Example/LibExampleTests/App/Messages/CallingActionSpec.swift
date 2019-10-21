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
            
            func newCall() -> Call { return Call(handle: "12345") }
            var call: Call!
            
            beforeEach { call = Call(handle: "12345") }
            afterEach  { sut = nil ; call = nil}
            
            context(".start"){
                beforeEach { sut = .start("12345") }
                
                it("equals .start")                              { expect(sut) == 	      .start("12345") }
                it("doesnt equals .start with differnet handle") { expect(sut) !=         .start("654321") }
                it("doesnt equal .stop")                         { expect(sut) != 		 .stop(newCall()) }
                it("doesnt equal .callDidStop")                  { expect(sut) != .callDidStop(newCall()) }
            }
            
            context(".dialing") {
                beforeEach { sut = .dialing(call) }
                
                it("equals other .dialing with equal call")           { expect(sut) ==     .dialing(call)      }
                it("doesnt equal other .dialing with different call") { expect(sut) !=     .dialing(newCall()) }
                it("doesnt equal .start")                             { expect(sut) !=       .start("12345")   }
                it("doesnt equals .stop")                             { expect(sut) !=        .stop(call)      }
                it("doesnt equal .callDidStop")                       { expect(sut) != .callDidStop(newCall()) }
            }
            
            context(".stop"){
                beforeEach { sut = .stop(call) }
                
                it("doesnt equal .start")                { expect(sut) !=         .start("12345") }
                it("equals .stop with same call")        { expect(sut) ==             .stop(call) }
                it("doesnt equal .stop with other call") { expect(sut) !=        .stop(newCall()) }
                it("doesnt equal .callDidStop")          { expect(sut) != .callDidStop(newCall()) }
            }
        }
    }
}
