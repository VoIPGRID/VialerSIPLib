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
            
            var user: User!
            var depend: Dependencies!

            beforeEach {
                depend = Dependencies(callStarter: Mock.CallStarter())
                sut = LogOut(dependencies:depend) { if case .logOutConfirmed(let u) = $0 { user = u }}
            }
            
            afterEach {
                user = nil
                sut = nil
            }
            
            it("logs user out") {
                sut.handle(request: .logOut(User(name: "the brain")))
                
                expect(user.name) == "the brain"
            }
        }
    }
}
