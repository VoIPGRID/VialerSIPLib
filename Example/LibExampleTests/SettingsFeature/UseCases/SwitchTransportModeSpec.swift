//
//  SwitchTransportModeSpec.swift
//  LibExampleTests
//
//  Created by Manuel on 14/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import Quick
import Nimble
@testable import LibExample

class SwitchTransportModeSpec: QuickSpec {
    override func spec() {
        describe("the SwitchTransportMode UseCase") {
            var sut: SwitchTransportMode!
            
            var receivedResponse: SwitchTransportMode.Response!
            
            beforeEach {
                sut = SwitchTransportMode { receivedResponse = $0 }
            }
            
            afterEach {
                receivedResponse = nil
                sut = nil
            }
            
            it("switches transport mode to tcp"){
                sut.handle(request: .setMode(.tcp))
                
                if case .modeWasActivated(let mode) = receivedResponse {
                    expect(mode) == .tcp
                } else {
                    fail()
                }
            }
            it("switches transport mode to udp"){
                sut.handle(request: .setMode(.udp))
                
                if case .modeWasActivated(let mode) = receivedResponse {
                    expect(mode) == .udp
                } else {
                    fail()
                }
            }
            it("switches transport mode to tls"){
                sut.handle(request: .setMode(.tls))
                
                if case .modeWasActivated(let mode) = receivedResponse {
                    expect(mode) == .tls
                } else {
                    fail()
                }
            }
        }
    }
}
