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

class Mock {
        class MessageHandler: MessageHandling {
        
        init(callBack: @escaping (Message) -> ()) {
            self.callBack = callBack
        }
        
        let callBack: (Message) -> ()
        
        func handle(msg: Message) {
            callBack(msg)
        }
    }
}

class SettingsFeatureSpec: QuickSpec {
    override func spec() {
        describe("the SettingsFeature UseCase") {
            var sut: SettingsFeature!
            
            var messageHandler: Mock.MessageHandler!
            var receivedModes: [TransportOption]!
            
            beforeEach {
                receivedModes = []
                messageHandler = Mock.MessageHandler {
                    if case .feature(.settings(.useCase(.transport(.action(.didActivate(let m)))))) = $0 {
                        receivedModes.append(m)
                    }
                }
                sut = SettingsFeature(with: messageHandler)
            }
            
            afterEach {
                receivedModes = nil
                messageHandler = nil
                sut = nil
            }
            
            it("switches transport modes") {
                sut.handle(feature: .settings(.useCase(.transport(.action(.activate(.udp))))))
                sut.handle(feature: .settings(.useCase(.transport(.action(.activate(.tcp))))))
                sut.handle(feature: .settings(.useCase(.transport(.action(.activate(.tls))))))
                sut.handle(feature: .settings(.useCase(.transport(.action(.activate(.udp))))))
                
                expect(receivedModes) == [.udp, .tcp, .tls, .udp]
            }
        }
    }
}
