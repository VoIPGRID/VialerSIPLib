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
            var recentListSize: RecentListSize!
            
            beforeEach {
                featureFlagger = Mock.FeatureFlagger()
                messageHandler = Mock.MessageHandler {
                    if case .feature(.flag(.useCase( .didEnable(.recentListSize(let size))))) = $0 { recentListSize = size  }
                    if case .feature(.flag(.useCase( .didEnable(_)                        ))) = $0 {        enabled = true  }
                    if case .feature(.flag(.useCase(.didDisable(_)                        ))) = $0 {        enabled = false }
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
            
            it("has enabled short recent call list size") {
                featureFlagger.flags = [FeatureFlag.recentListSize(.short): true]
                sut.handle(feature: .flag(.useCase(.isEnbaled(.recentListSize(.short)))))
                
                expect(enabled).to(beTrue())
                expect(recentListSize) == .short
            }
            
            it("hasnt enabled medium recent call list size") {
                featureFlagger.flags = [FeatureFlag.recentListSize(.short): true]
                sut.handle(feature: .flag(.useCase(.isEnbaled(.recentListSize(.medium)))))
                
                expect(enabled).to(beFalse())
                expect(recentListSize) != .medium
            }
        }
    }
}
