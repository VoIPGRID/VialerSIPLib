//
//  LogInSpec.swift
//  LibExampleTests
//
//  Created by Manuel on 14/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import Quick
import Nimble
@testable import LibExample

class LogInSpec: QuickSpec {
    override func spec() {
        describe("the LogIn UseCase") {
            var sut: LogIn!
            var user: User!

            beforeEach {
                sut = LogIn(dependencies:self.dependencies) { if case .logInConfirmed(let u) = $0 { user = u }}
            }
            
            afterEach {
                sut = nil
                user = nil
            }
            
            it("logs user in"){
                sut.handle(request: .logIn("the brain", "password"))
                
                expect(user.name).to(equal("the brain"))
            }
        }
    }
    
    var dependencies: Dependencies {
        Dependencies(
            currentAppStateFetcher: Mock.CurrentAppStateFetcher(),
                       callStarter: Mock.CallStarter(),
                    statePersister: Mock.StatePersister(),
                  ipAddressChecker: IPAddressChecker()
        )
    }
}
