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
            var depend: Dependencies!

            beforeEach {
                depend = Dependencies(callStarter: Mock.CallStarter())
                sut = LogIn(dependencies:depend) { if case .logInConfirmed(let u) = $0 { user = u }}
            }
            
            afterEach {
                depend = nil
                sut = nil
                user = nil
            }
            
            it("logs user in"){
                sut.handle(request: .logIn("the brain", "password"))
                
                expect(user.name).to(equal("the brain"))
            }
        }
    }
}
