//
//  VSLCallManagerTests.m
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import <VialerSIPLib/VSLAccount.h>
#import <VialerSIPLib/VSLCall.h>
#import <VialerSIPLib/VSLCallManager.h>

@interface VSLCallManagerTests : XCTestCase
@property (strong, nonatomic) id accountMock;
@property (strong, nonatomic) VSLCallManager *callManagerUnderTest;
@end

@implementation VSLCallManagerTests

- (void)setUp {
    [super setUp];
    self.accountMock = OCMStrictClassMock([VSLAccount class]);
    self.callManagerUnderTest = [[VSLCallManager alloc] init];
}

- (void)tearDown {
    [self.accountMock stopMocking];
    self.accountMock = nil;
    [super tearDown];
}

- (void)testCallsForAccount {
    VSLCall *mockCall1 = [[VSLCall alloc] initInboundCallWithCallId:1 account:self.accountMock];
    VSLCall *mockCall2 = [[VSLCall alloc] initOutboundCallWithNumberToCall:@"123" account:self.accountMock];

    [self.callManagerUnderTest addCall:mockCall1];
    [self.callManagerUnderTest addCall:mockCall2];

    NSArray *callsForAccount = [self.callManagerUnderTest callsForAccount:self.accountMock];

    XCTAssertNotNil(callsForAccount, @"Calls array for account should not have been nil");
    XCTAssert(callsForAccount.count == 2, @"Incorrect number of calls for account returned. Calls count:%@", [[NSNumber numberWithUnsignedInteger:callsForAccount.count] stringValue]);
    XCTAssert([callsForAccount containsObject:mockCall1], @"mockCall1 should have been in calls array for account");
    XCTAssert([callsForAccount containsObject:mockCall2], @"mockCall2 should have been in calls array for account");

    [self.accountMock verify];
}

- (void)testCallForDifferentAccountShouldNotBeReturned {
    id differentAccountMock = OCMStrictClassMock([VSLAccount class]);
    VSLCall *mockCall1 = [[VSLCall alloc] initInboundCallWithCallId:1 account:differentAccountMock];
    VSLCall *mockCall2 = [[VSLCall alloc] initOutboundCallWithNumberToCall:@"123" account:differentAccountMock];

    [self.callManagerUnderTest addCall:mockCall1];
    [self.callManagerUnderTest addCall:mockCall2];

    NSArray *callsForAccount = [self.callManagerUnderTest callsForAccount:self.accountMock];

    XCTAssertNil(callsForAccount, @"Calls for account array should have been nil");
    XCTAssert(callsForAccount.count == 0, @"Incorrect number of calls for account returned. Calls count:%@", [[NSNumber numberWithUnsignedInteger:callsForAccount.count] stringValue]);
    XCTAssert(![callsForAccount containsObject:mockCall1], @"mockCall1 should have been in calls array for account");
    XCTAssert(![callsForAccount containsObject:mockCall2], @"mockCall2 should have been in calls array for account");

    [self.accountMock verify];
    [differentAccountMock verify];
}

@end
