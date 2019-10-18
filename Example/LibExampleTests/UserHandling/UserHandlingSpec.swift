//
//  UserHandlingSpec.swift
//  LibExampleTests
//
//  Created by Manuel on 14/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import Quick
import Nimble
@testable import LibExample

class UserHandlingFeatureSpec: QuickSpec, MessageHandling {
    
    var loggedInUser:User!
    var loggedOutUser:User!
    var depend: Dependencies!

    func handle(msg: Message) {
        if case .feature(.userHandling(.useCase(.login (.action(.logInConfirmed (let user)))))) = msg { self.loggedInUser  = user }
        if case .feature(.userHandling(.useCase(.logout(.action(.logOutConfirmed(let user)))))) = msg { self.loggedOutUser = user }
    }
    
    override func spec() {
        describe("the UserHandling Feature") {
            var sut: UserHandlingFeature!
            
            beforeEach {
                self.depend = Dependencies(callStarter: Mock.CallStarter())
                sut = UserHandlingFeature(with: self, dependencies: self.depend)
            }
            
            afterEach {
                sut = nil
                self.loggedOutUser = nil
                self.loggedInUser = nil
                self.depend = nil
            }
            
            it("logs in user"){
                sut.handle(feature: .userHandling(.useCase(.login(.action(.logIn("pinky", "password"))))))
                
                expect(self.loggedInUser.name) == "pinky"
            }
            
            it("logs out user"){
                sut.handle(feature: .userHandling(.useCase(.logout(.action(.logOut(User(name:"the brain")))))))
                
                expect(self.loggedOutUser.name) == "the brain"
            }
        }
    }
}
