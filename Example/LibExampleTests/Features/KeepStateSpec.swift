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
            var stateWasReset = false
            var resetError: Error?
            var newPassword: String?
            beforeEach {
                
                retrievedTransportModes = []
                statePesister = Mock.StatePersister()
                sut = KeepState(dependencies:
                    Dependencies(currentAppStateFetcher: CurrentAppStateFetcher(),
                                            callStarter: Mock.CallStarter(),
                                         statePersister: statePesister!,
                                         featureFlagger: FeatureFlagger(),
                                       ipAddressChecker: IPAddressChecker()
                    )
                ) { response in
                    switch response {
                    case .stateChanged(let state):
                        retrievedTransportModes?.append(state.transportMode)
                    case .stateLoaded(let state):
                        loadedState = state
                    case .failedPersisting(_, let error):
                        retrievedError = error
                    case .failedLoadingState(let error):
                        retrievedError = error
                    case .stateWasReset:
                        stateWasReset = true
                    case .failedDeletingState(let error):
                        resetError = error
                    case .passwordChanged(let state):
                        newPassword = state.encryptedPassword
                    case .passwordChangeFailed(_):
                        break
                    }
                }
            }
            
            afterEach {
                newPassword = nil
                resetError = nil
                stateWasReset = false
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
            
            it("receives an error if it fails to reset state") {
                statePesister?.shouldFailResetting = true
                sut.handle(request: .resetState)
                
                expect(resetError).toNot(beNil())
            }
            
            it("resets the app's state") {
                sut.handle(request: .resetState)
                
                expect(stateWasReset).to(beTrue())
            }
            
            it("resets the app's state") {
                sut.handle(request: .setPassword("4711", AppState(transportMode: .tls, accountNumber:"0815", serverAddress: "server", encryptedPassword:"1234567890" )))
                
                expect(newPassword).to(equal("4711"))
            }
        }
    }
}
