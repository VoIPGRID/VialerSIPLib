//
//  LogOutSpec.swift
//  LibExampleTests
//
//  Created by Manuel on 14/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import Quick
import Nimble
@testable import LibExample

class LogOutSpec: QuickSpec {
    override func spec() {
        describe("the LogOut UseCase") {
            var sut: LogOut!
            var logOutResponse: LogOut.Response?
            
            beforeEach {
                sut = LogOut { logOutResponse = $0 }
            }
            
            afterEach {
                logOutResponse = nil
                sut = nil
            }
            
            it("logs user out") {
                sut.handle(request: .logOut(User(name: "the brain")))
                
                if case .logOutConfirmed(let user) = logOutResponse {
                    expect(user.name) == "the brain"
                } else {
                    fail()
                }
            }
        }
    }
}
