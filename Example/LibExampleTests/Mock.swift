//
//  Mock.swift
//  LibExampleTests
//
//  Created by Manuel on 15/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//
import Foundation
@testable import LibExample

class Mock {
    class MessageHandler: MessageHandling, MessageSubscriber {
        
        init(callBack: @escaping (Message) -> ()) {
            self.callBack = callBack
        }
        
        let callBack: (Message) -> ()
        
        func handle(msg: Message) { callBack(msg) }
    }
    
    struct CallStarter: CallStarting {
        init() {}
        
        var appState: AppState?
        
        var deferResponse: ((Bool) -> DispatchTimeInterval) = {
            switch $0 {
            case  true: return .milliseconds(10)
            case false: return .milliseconds(7)
            }
        }

        var callback: ((Bool, Call) -> Void)?
        func start(call: Call) {
            checkHandle(call.handle)
                ? delay(by: deferResponse( true)) { self.callback?( true, call)}
                : delay(by: deferResponse(false)) { self.callback?(false, call)}
        }
    }
    
    struct CallManager: CallManaging {
        init(shouldSucceed: Bool) {
            self.shouldSucceed = shouldSucceed
        }
        
        let shouldSucceed: Bool
        
        func startCall(toNumber: String, for: VSLAccount, completion: @escaping ((VSLCall?, Error?) -> ())) {
            shouldSucceed
                ? completion(VSLCall(inboundCallWithCallId: 9, account: VSLAccount(callManager: VSLCallManager())), nil)
                : completion(nil, NSError())
        }
    }
    
    class StatePersister: StatePersisting  {
        var shouldFailLoading = false
        var shouldFailPersisting = false
        var shouldFailResetting = false

        private var appState: AppState! = AppState(transportMode: .udp, accountNumber: "0815", serverAddress: "server",encryptedPassword: "08/15")
        func persist(state: AppState) throws {
            if shouldFailPersisting {
                throw NSError(domain: "failed loading", code: 501, userInfo: nil)
            }
            appState = state
        }
        
        func loadState() throws -> AppState? {
            if shouldFailLoading {
                throw NSError(domain: "failed loading", code: 501, userInfo: nil)
            }
            return appState
        }
        
        func deleteState() throws {
            if shouldFailResetting {
                throw NSError(domain: "failed resetting", code: 503, userInfo: nil)
            }
        }
    }
    
    class CurrentAppStateFetcher: CurrentAppStateFetching {
        var appState: AppState!
        
        func handle(msg: Message) { }
    }
    
    class FeatureToggler: FeatureToggling {
        init(deactivatedFlags: [FeatureFlag]) {
            self.deactivatedFlags = deactivatedFlags
        }
        
        var featureFlagModels: [FeatureFlagModel] = []
        let deactivatedFlags: [FeatureFlag]
        
        func isActive(flag: FeatureFlag) -> Bool {
            return deactivatedFlags.filter { (f) -> Bool in
                return f == flag
            }.count == 0
        }
        
        func process(msg: Message) -> Message? {
            return msg
        }
    }
}
