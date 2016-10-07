//
//  VSLEndpointTests.m
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import <VialerSIPLib/VSLAccount.h>
#import <VialerSIPLib/VSLAccountConfiguration.h>
#import <VialerSIPLib/VSLCallManager.h>
#import <VialerSIPLib/VSLEndpoint.h>

@interface VSLEndpointTests : XCTestCase
@property (strong, nonatomic) id callManagerMock;
@property (strong, nonatomic) VSLEndpoint *endpoint;
@end

@implementation VSLEndpointTests

- (void)setUp {
    [super setUp];
    self.endpoint = [[VSLEndpoint alloc] init];
    self.callManagerMock = OCMStrictClassMock([VSLCallManager class]);
}

- (void)tearDown {
    self.endpoint = nil;
    [self.callManagerMock stopMocking];
    self.callManagerMock = nil;
    [super tearDown];
}

- (void)testEndpointHasOnDefaultNoAccounts {
    XCTAssertNotNil(self.endpoint.accounts, @"there should be an array");
    XCTAssertEqual([self.endpoint.accounts count], 0, @"There should be no accounts on default");
}

- (void)testEndpointWithAddedAccountShouldHaveTheAccount {
    VSLAccount *account = [[VSLAccount alloc] initWithCallManager:self.callManagerMock];
    [self.endpoint addAccount:account];

    XCTAssertTrue([self.endpoint.accounts containsObject:account], @"The account should have been added to the array");
}

- (void)testCanRemoveAddedAccount {
    VSLAccount *account = [[VSLAccount alloc] initWithCallManager:self.callManagerMock];
    [self.endpoint addAccount:account];
    [self.endpoint removeAccount:account];

    XCTAssertFalse([self.endpoint.accounts containsObject:account], @"The account should have been removed from the array");
}

- (void)testNoAccountFoundGetAccountWithSiperUsernameReturnsNil {
    [self.endpoint addAccount:[[VSLAccount alloc] initWithCallManager:self.callManagerMock]];

    VSLAccount *account = [self.endpoint getAccountWithSipAccount:@"42"];
    XCTAssertNil(account, @"There should be no account found when the sip username is not found");

    [self.endpoint removeAccount:account];
}

- (void)testAccountFoundFromGetAccountWithSipAccount {
    VSLAccountConfiguration *config = [[VSLAccountConfiguration alloc] init];
    config.sipAccount = @"42";
    config.sipDomain = @"sip.test.com";

    VSLAccount *testAccount = [[VSLAccount alloc] initWithCallManager:self.callManagerMock];
    [testAccount configureWithAccountConfiguration:config error:nil];
    [self.endpoint addAccount:testAccount];

    VSLAccount *account = [self.endpoint getAccountWithSipAccount:@"42"];
    XCTAssertEqualObjects(account, testAccount, @"There should be an account found.");

    [self.endpoint removeAccount:testAccount];
}

@end
