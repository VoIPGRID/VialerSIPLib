//
//  VSLAccountTests.m
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import <OCMock/OCMock.h>
#import <VialerPJSIP/pjsua.h>
#import <VialerSIPLib/VSLAccount.h>
#import <VialerSIPLib/VSLCallManager.h>
#import <VialerSIPLib/VSLEndpoint.h>
#import <XCTest/XCTest.h>

@interface VSLAccountTests : XCTestCase
@property (strong, nonatomic) id callManagerMock;
@property (strong, nonatomic) VSLAccount *account;
@end

@implementation VSLAccountTests

- (void)setUp {
    [super setUp];
    self.callManagerMock = OCMStrictClassMock([VSLCallManager class]);
    self.account = [[VSLAccount alloc] initWithCallManager:self.callManagerMock];
}

- (void)tearDown {
    self.account = nil;
    [self.callManagerMock stopMocking];
    self.callManagerMock = nil;
    [super tearDown];
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
    config.sipAccount = @"test";
    config.sipDomain = @"sip.test.com";

    NSError *error;
    BOOL success = [self.account configureWithAccountConfiguration:config error:&error];
    XCTAssertTrue(success);
    XCTAssertNil(error);

    [self.account removeAccount];
}

- (void)testAccountHasAValidAccountIdWhenConfigured {
    VSLAccountConfiguration *config = [[VSLAccountConfiguration alloc] init];
    config.sipAccount = @"test";
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
    config.sipAccount = @"test";
    config.sipDomain = @"sip.test.com";

    [self.account configureWithAccountConfiguration:config error:nil];
    XCTAssertEqual(self.account.accountConfiguration, config, @"The config should have been stored");

    [self.account removeAccount];
}

- (void)testAccountHasNoConfigWhenWrongConfigured {
    VSLAccountConfiguration *config = [[VSLAccountConfiguration alloc] init];
    config.sipAccount = @"1234";

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

- (void)testAccountRegistrationStatusIsInvalidOnDefault {
    XCTAssertEqual(self.account.registrationStatus, 0, @"The registration status of an account should be 0 on default.");
}

- (void)testAccountRegistrationExpireTimeIsNegativeValueOndefault {
    XCTAssertEqual(self.account.registrationExpiresTime, -1, @"The account should have a negative registration time on default.");
}

- (void)testAccountIsntRegisteredOnDefault {
    XCTAssertFalse(self.account.isRegistered, @"An account should not be registered on default.");
}

- (void)testAccountCanUnRegisterWhenNotRegistered {
    NSError *error;
    XCTAssertTrue([self.account unregisterAccount:&error], @"It should be possible to unregister when not registered");
    XCTAssertNil(error, @"There should be no error when unregistering the account.");
}

- (void)testAccountCanRegister {
    VSLEndpoint *endpoint = [VSLEndpoint sharedEndpoint];
    VSLAccountConfiguration *config = [[VSLAccountConfiguration alloc] init];
    config.sipAccount = @"test";
    config.sipDomain = @"sip.test.com";
    [self.account configureWithAccountConfiguration:config error:nil];

    [self.account registerAccountWithCompletion:^(BOOL success, NSError * _Nullable error) {
        XCTAssertNil(error, @"There should be no error when registering an account");
        XCTAssertEqual([endpoint.accounts count], 1, @"There should be one account.");
        [endpoint removeAccount:self.account];
        XCTAssertEqual([endpoint.accounts count], 0, @"There should be no account.");
    }];
}

@end
