//
//  VSLAccountTests.m
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import <OCMock/OCMock.h>
#import <VialerPJSIP/pjsua.h>
#import <VialerSIPLib-iOS/VSLAccount.h>
#import <VialerSIPLib-iOS/VSLEndpoint.h>
#import <XCTest/XCTest.h>

@interface VSLAccountTests : XCTestCase
@property (strong, nonatomic) VSLAccount *account;
@end

@implementation VSLAccountTests

- (void)setUp {
    [super setUp];
    self.account = [[VSLAccount alloc] init];
}

- (void)testAccountHasDefaultInvalidAccountId {
    XCTAssertEqual(self.account.accountId, PJSUA_INVALID_ID, @"On default the accountId should be invalid");
}

- (void)testAccountHasErrorWhenNoDomainInConfig {
    VSLAccountConfiguration *config = [[VSLAccountConfiguration alloc] init];
    config.sipDomain = @"";

    NSError *error;
    BOOL success = [self.account configureWithAccountConfiguration:config error:&error];
    XCTAssertFalse(success);
    XCTAssertNotNil(error);
}

- (void)testAccountHasNoErrorWhenDomainAndUsernameInConfig {
    VSLAccountConfiguration *config = [[VSLAccountConfiguration alloc] init];
    config.sipUsername = @"test";
    config.sipDomain = @"sip.test.com";

    NSError *error;
    BOOL success = [self.account configureWithAccountConfiguration:config error:&error];
    XCTAssertTrue(success);
    XCTAssertNil(error);

    [self.account removeAccount];
}

- (void)testAccountHasAValidAccountIdWhenConfigured {
    VSLAccountConfiguration *config = [[VSLAccountConfiguration alloc] init];
    config.sipUsername = @"test";
    config.sipDomain = @"sip.test.com";

    NSError *error;
    BOOL success = [self.account configureWithAccountConfiguration:config error:&error];
    XCTAssertTrue(success);
    XCTAssertNil(error);
    XCTAssertNotEqual(self.account.accountId, PJSUA_INVALID_ID);

    [self.account removeAccount];
}

- (void)testAccountHasACorrectConfigWhenProperlyConfigured {
    VSLAccountConfiguration *config = [[VSLAccountConfiguration alloc] init];
    config.sipUsername = @"test";
    config.sipDomain = @"sip.test.com";

    [self.account configureWithAccountConfiguration:config error:nil];
    XCTAssertEqual(self.account.accountConfiguration, config, @"The config should have been stored");

    [self.account removeAccount];
}

- (void)testAccountHasNoConfigWhenWrongConfigured {
    VSLAccountConfiguration *config = [[VSLAccountConfiguration alloc] init];
    config.sipUsername = @"1234";

    NSError *error = nil;
    [self.account configureWithAccountConfiguration:config error:&error];
    XCTAssertNil(self.account.accountConfiguration, @"there should be no configuration when config isn't correct");
}

- (void)testAccountStateIsOfflineOnDefault {
    XCTAssertEqual(self.account.accountState, VSLAccountStateOffline);
}

- (void)testAccountIsntAddedToEndpointOnConfiguration {
    id endpointMock = OCMClassMock([VSLEndpoint class]);
    OCMStub(ClassMethod([endpointMock sharedEndpoint])).andReturn(endpointMock);
    [[endpointMock reject] addAccount:[OCMArg any]];

    VSLAccountConfiguration *config = [[VSLAccountConfiguration alloc] init];
    config.sipDomain = @"sip.test.com";

    [self.account configureWithAccountConfiguration:config error:nil];
    [endpointMock stopMocking];
}

@end
