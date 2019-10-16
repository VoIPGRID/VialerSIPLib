//
//  CallSpec.swift
//  LibExampleTests
//
//  Created by Manuel on 16/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import Quick
import Nimble
@testable import LibExample

class CallSpec: QuickSpec {
    override func spec() {
        describe("the Call Entity") {
            context("in comparison"){
                
                var call0: Call!
                var call1: Call!
                
                beforeEach {
                    call0 = Call(handle: "159753")
                }
                
                afterEach {
                    call1 = nil
                    call0 = nil
                }
                
                it("equals to another date with same state, uninitialized by default") {
                    call1 = transform(call0, with: .uninitialized)

                    expect(call0) == call1
                }
                
                it("doesnt equal to another date with a different state") {
                    call1 = transform(call0, with: .started)

                    expect(call0) != call1
                }
            }
        }
    }
}
