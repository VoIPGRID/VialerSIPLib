//
//  KeepStateSpec.swift
//  LibExampleTests
//
//  Created by Manuel on 04/11/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import Quick
import Nimble
@testable import LibExample

class KeepStateSpec: QuickSpec {
    override func spec() {
        describe("KeepState"){
            var sut:KeepState!
            var retrievedError: Error?
            var retrievedTransportModes: [TransportMode]?
            var loadedState: AppState?
            var statePesister: Mock.StatePersister?
            
            beforeEach {
                
                retrievedTransportModes = []
                statePesister = Mock.StatePersister()
                sut = KeepState(dependencies: Dependencies(callStarter: Mock.CallStarter(), statePersister: statePesister!, currentAppStateFetcher: CurrentAppStateFetcher())) { response in
                    switch response {
                    case .stateChanged(let state):
                        retrievedTransportModes?.append(state.transportMode)
                    case .stateLoaded(let state):
                        loadedState = state
                    case .failedPersisting(_, let error):
                        retrievedError = error
                    case .failedLoadingState(let error):
                        retrievedError = error
                    }
                }
            }
            
            afterEach {
                statePesister = nil
                loadedState = nil
                retrievedError = nil
                retrievedTransportModes = nil
                sut = nil
            }
            
            it("keeps the changed transport mode") {
                sut.handle(request: .setTransportMode(.tcp, sut.state))
                sut.handle(request: .setTransportMode(.udp, sut.state))
                sut.handle(request: .setTransportMode(.tls, sut.state))
                
                expect(retrievedTransportModes) == [.tcp, .udp, .tls]
                expect(retrievedError).to(beNil())
            }
            
            it("loads initial state") {
                sut.handle(request: .loadState)
                
                expect(loadedState?.transportMode) == .udp
            }
            
            it("receives an error if it fails to load initial state") {
                statePesister?.shouldFailLoading = true
                sut.handle(request: .loadState)
                
                expect(retrievedError).toNot(beNil())
            }
            
            it("receives an error if it fails to persist state") {
                statePesister?.shouldFailPersisting = true
                sut.handle(request: .setTransportMode(.tcp, sut.state))

                expect(retrievedError).toNot(beNil())
            }
        }
    }
}
