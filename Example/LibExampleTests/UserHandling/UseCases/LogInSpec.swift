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
            
            var logInResponse: LogIn.Response?
            
            beforeEach {
                sut = LogIn { logInResponse = $0 }
            }
            
            afterEach {
                sut = nil
                logInResponse = nil
            }
            
            it("logs user in"){
                sut.handle(request: .logIn("the brain", "password"))
                
                if case .logInConfirmed(let user) = logInResponse {
                    expect(user.name).to(equal("the brain"))
                } else {
                    fail()
                }
            }
        }
    }
}
