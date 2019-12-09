//
//  SettingsFeatureSpec.swift
//  LibExampleTests
//
//  Created by Manuel on 14/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import Quick
import Nimble
@testable import LibExample

class SettingsFeatureSpec: QuickSpec {
    override func spec() {
        describe("the SettingsFeature UseCase") {
            var sut: SettingsFeature!
            var messageHandler: Mock.MessageHandler!
            var receivedModes: [TransportMode]!
            var changedAddressSuccess: Bool!
            var changedAddress: String!

            beforeEach {
                receivedModes = []
                messageHandler = Mock.MessageHandler {
                    if case .feature(.settings(.useCase(.transport(.action(        .didActivate(let m)))))) = $0 { receivedModes.append(m)}
                    if case .feature(.settings(.useCase(   .server(.action(     .addressChanged(let a)))))) = $0 { changedAddress = a; changedAddressSuccess = true }
                    if case .feature(.settings(.useCase(   .server(.action(.addressChangeFailed(let a)))))) = $0 { changedAddress = a; changedAddressSuccess = false }
                }
                sut = SettingsFeature(with: messageHandler, dependencies: self.dependencies)
            }
            
            afterEach {
                changedAddress = nil
                changedAddressSuccess = nil
                receivedModes = nil
                messageHandler = nil
                sut = nil
            }
            
            it("switches transport modes") {
                [.udp, .tcp, .tls, .udp].forEach {
                    sut.handle(feature: .settings(.useCase(.transport(.action(.activate($0))))))
                }
                
                expect(receivedModes) == [.udp, .tcp, .tls, .udp]
            }
            
            it("changes serer address"){
                sut.handle(feature: .settings(.useCase(.server(.action(.changeAddress("127.0.0.1"))))))
                
                expect(changedAddress) == "127.0.0.1"
            }
            
            it("changes server address"){
                sut.handle(feature: .settings(.useCase(.server(.action(.changeAddress("127.0.0.1"))))))
                
                expect(changedAddressSuccess) == true
                expect(changedAddress) == "127.0.0.1"
            }
            
            it("fails changing server address"){
                sut.handle(feature: .settings(.useCase(.server(.action(.changeAddress("127.0.1"))))))
                
                expect(changedAddressSuccess) == false
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
