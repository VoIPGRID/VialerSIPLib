//
//  FeatureFlagFeatureSpec.swift
//  LibExampleTests
//
//  Created by Manuel on 02/12/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import Quick
import Nimble
@testable import LibExample

class FeatureFlagFeatureSpec: QuickSpec {
    
    override func spec() {
        describe("FeatureFlagFeature"){
            var sut: FeatureFlagFeature!
            
            var messageHandler: Mock.MessageHandler!
            var featureFlagger: Mock.FeatureFlagger!
            
            var dependencies: Dependencies {
                Dependencies(
                    currentAppStateFetcher: Mock.CurrentAppStateFetcher(),
                               callStarter: Mock.CallStarter(),
                            statePersister: Mock.StatePersister(),
                            featureFlagger: featureFlagger
                )
            }
            
            var enabled: Bool? = nil
            var numberOfEntries = 0
            
            beforeEach {
                featureFlagger = Mock.FeatureFlagger()
                messageHandler = Mock.MessageHandler {
                    if case .feature(.flag(.useCase( .didEnable(.recentListSize(let number))))) = $0 { numberOfEntries = number }
                    if case .feature(.flag(.useCase( .didEnable(_)                          ))) = $0 {         enabled = true   }
                    if case .feature(.flag(.useCase(.didDisable(_)                          ))) = $0 {         enabled = false  }
                }
                sut = FeatureFlagFeature(with: messageHandler, dependencies: dependencies)
            }
            
            afterEach {
                sut = nil
                messageHandler = nil
                featureFlagger = nil
            }
            
            it("has startCall enabled") {
                featureFlagger.flags = [FeatureFlag.startCall: true]
                sut.handle(feature: .flag(.useCase(.isEnbaled(.startCall))))
                
                expect(enabled).to(beTrue())
            }
            
            it("has startCall disabled") {
                featureFlagger.flags = [FeatureFlag.startCall: false]
                sut.handle(feature: .flag(.useCase(.isEnbaled(.startCall))))
                
                expect(enabled).to(beFalse())
            }
            
            it("has enabled 10 recent call entries") {
                featureFlagger.flags = [FeatureFlag.recentListSize(10): true]
                sut.handle(feature: .flag(.useCase(.isEnbaled(.recentListSize(10)))))
                
                expect(enabled).to(beTrue())
                expect(numberOfEntries) == 10
            }
            
            it("hasnt enabled 20 recent call entries") {
                featureFlagger.flags = [FeatureFlag.recentListSize(10): true]
                sut.handle(feature: .flag(.useCase(.isEnbaled(.recentListSize(20)))))
                
                expect(enabled).to(beFalse())
                expect(numberOfEntries) != 20
            }
        }
    }
}
