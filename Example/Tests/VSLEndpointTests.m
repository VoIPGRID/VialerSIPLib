//
//  VSLEndpointTests.m
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import <VialerSIPLib-iOS/VSLAccount.h>
#import <VialerSIPLib-iOS/VSLAccountConfiguration.h>
#import <VialerSIPLib-iOS/VSLEndpoint.h>

@interface VSLEndpointTests : XCTestCase
@property (strong, nonatomic) VSLEndpoint *endpoint;
@end

@implementation VSLEndpointTests

- (void)setUp {
    [super setUp];
    self.endpoint = [VSLEndpoint sharedEndpoint];
}

- (void)testEndpointHasOnDefaultNoAccounts {
    XCTAssertNotNil(self.endpoint.accounts, @"there should be an array");
    XCTAssertEqual([self.endpoint.accounts count], 0, @"There should be no accounts on default");
}

- (void)testEndpointWithAddedAccountShouldHaveTheAccount {
    VSLAccount *account = [[VSLAccount alloc] init];
    [self.endpoint addAccount:account];

    XCTAssertTrue([self.endpoint.accounts containsObject:account], @"The account should have been added to the array");
}

- (void)testCanRemoveAddedAccount {
    VSLAccount *account = [[VSLAccount alloc] init];
    [self.endpoint addAccount:account];
    [self.endpoint removeAccount:account];

    XCTAssertFalse([self.endpoint.accounts containsObject:account], @"The account should have been removed from the array");
}

- (void)testNoAccountFoundGetAccountWithSiperUsernameReturnsNil {
    [self.endpoint addAccount:[[VSLAccount alloc] init]];

    VSLAccount *account = [self.endpoint getAccountWithSipUsername:@"42"];
    XCTAssertNil(account, @"There should be no account found when the sip username is not found");

    [self.endpoint removeAccount:account];
}

- (void)testAccountFoundFromGetAccountWithSipUsername {
    VSLAccountConfiguration *config = [[VSLAccountConfiguration alloc] init];
    config.sipUsername = @"42";
    config.sipDomain = @"sip.test.com";

    VSLAccount *testAccount = [[VSLAccount alloc] init];
    [testAccount configureWithAccountConfiguration:config error:nil];
    [self.endpoint addAccount:testAccount];

    VSLAccount *account = [self.endpoint getAccountWithSipUsername:@"42"];
    XCTAssertEqualObjects(account, testAccount, @"There should be an account found.");

    [self.endpoint removeAccount:testAccount];
}

@end
