//
//  VialerSIPLibTests.m
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import <VialerSIPLib-iOS/VSLCall.h>
#import <VialerSIPLib-iOS/VSLEndpoint.h>
#import <VialerSIPLib-iOS/VialerSIPLib.h>

@interface VialerSIPLibTests : XCTestCase

@end

@implementation VialerSIPLibTests

- (void)testEndpointIncomingCallBlock {
    id endpointMock = OCMClassMock([VSLEndpoint class]);
    OCMStub(ClassMethod([endpointMock sharedEndpoint])).andReturn(endpointMock);

    [VialerSIPLib sharedInstance].incomingCallBlock = ^(VSLCall * _Nonnull call) {

    };

    OCMVerify([endpointMock setIncomingCallBlock:[OCMArg any]]);
}

- (void)testEndpointIncomingCallBlockWithCall {
    id callMock = OCMClassMock([VSLCall class]);

    id endpointMock = OCMClassMock([VSLEndpoint class]);
    OCMStub(ClassMethod([endpointMock sharedEndpoint])).andReturn(endpointMock);
    OCMStub([endpointMock setIncomingCallBlock:([OCMArg invokeBlockWithArgs:callMock, nil])]);

    [VialerSIPLib sharedInstance].incomingCallBlock = ^(VSLCall * _Nonnull call) {
        XCTAssertEqualObjects(callMock, call, @"Correct call should have been set.");
    };

}
@end
