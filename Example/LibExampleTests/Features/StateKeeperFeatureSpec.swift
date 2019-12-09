//
//  StateKeeperSpec.swift
//  LibExampleTests
//
//  Created by Manuel on 04/11/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import Quick
import Nimble
@testable import LibExample

class StateKeeperFeatureSpec: QuickSpec {
    
    override func spec() {
        describe("StateKeeperFeature"){
            var sut: StateKeeperFeature!
            var messageHandler: Mock.MessageHandler!
            var changedState: AppState?
            
            beforeEach {
                messageHandler = Mock.MessageHandler() { msg in
                    if case .feature(.state(.useCase(.stateChanged(let state)))) = msg { changedState = state }
                }
                sut = StateKeeperFeature(
                    with: messageHandler,
                    dependencies: self.dependencies
                )
            }
            
            afterEach {
                changedState = nil
                messageHandler = nil
                sut = nil
            }
            
            it("track changes for transport mode") {
                sut.handle(feature: .settings(.useCase(.transport(.action(.didActivate(.udp))))))
                
                expect(changedState?.transportMode).to(equal(.udp))
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
