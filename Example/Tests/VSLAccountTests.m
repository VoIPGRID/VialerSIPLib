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

    [self.account configureWithAccountConfiguration:config withCompletion:^(NSError * _Nullable error) {
        XCTAssertNotNil(error, @"There should be an error");
    }];
}

- (void)testAccountHasNoErrorWhenDomainAndUsernameInConfig {
    VSLAccountConfiguration *config = [[VSLAccountConfiguration alloc] init];
    config.sipUsername = @"test";
    config.sipDomain = @"sip.test.com";

    [self.account configureWithAccountConfiguration:config withCompletion:^(NSError * _Nullable error) {
        XCTAssertNil(error, @"There should be no error");
    }];
}

- (void)testAccountHasAValidAccountIdWhenConfigured {
    VSLAccountConfiguration *config = [[VSLAccountConfiguration alloc] init];
    config.sipUsername = @"test";
    config.sipDomain = @"sip.test.com";

    [self.account configureWithAccountConfiguration:config withCompletion:^(NSError * _Nullable error) {
        XCTAssertNotEqual(self.account.accountId, PJSUA_INVALID_ID);
    }];
}

- (void)testAccountHasACorrectConfigWhenProperlyConfigured {
    VSLAccountConfiguration *config = [[VSLAccountConfiguration alloc] init];
    config.sipUsername = @"test";
    config.sipDomain = @"sip.test.com";

    [self.account configureWithAccountConfiguration:config withCompletion:^(NSError * _Nullable error) {
        XCTAssertEqual(self.account.accountConfiguration, config, @"The config should have been stored");
    }];
}

- (void)testAccountHasNoConfigWhenWrongConfigured {
    VSLAccountConfiguration *config = [[VSLAccountConfiguration alloc] init];
    config.sipUsername = @"1234";

    [self.account configureWithAccountConfiguration:config withCompletion:^(NSError * _Nullable error) {
        XCTAssertNil(self.account.accountConfiguration, @"there should be no configuration when config isn't correct");
    }];
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

    [self.account configureWithAccountConfiguration:config withCompletion:^(NSError * _Nullable error) {}];
    [endpointMock stopMocking];
}

@end
