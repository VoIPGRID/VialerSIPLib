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
            var mode: TransportMode!

            beforeEach {
                sut = SwitchTransportMode(dependencies: self.dependencies) { if case .modeWasActivated(let m) = $0 { mode = m } }
            }
            
            afterEach {
                mode = nil
                sut = nil
            }
            
            it("switches transport mode to tcp"){
                sut.handle(request: .setMode(.tcp))
                
                expect(mode) == .tcp
            }
            
            it("switches transport mode to udp"){
                sut.handle(request: .setMode(.udp))
                
                expect(mode) == .udp
            }
            
            it("switches transport mode to tls"){
                sut.handle(request: .setMode(.tls))
                
                expect(mode) == .tls
            }
        }
    }
    
    var dependencies: Dependencies {
        Dependencies(
            currentAppStateFetcher: Mock.CurrentAppStateFetcher(),
                       callStarter: Mock.CallStarter(),
                    statePersister: Mock.StatePersister(),
                    featureFlagger: FeatureFlagger(),
                  ipAddressChecker: IPAddressChecker()
        )
    }
}
