//
//  VSLAccountConfigurationTests.m
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import <VSLAccountConfiguration.h>
#import <XCTest/XCTest.h>

@interface VSLAccountConfigurationTests : XCTestCase
@property (strong, nonatomic) VSLAccountConfiguration *configuration;
@end

@implementation VSLAccountConfigurationTests

- (void)setUp {
    [super setUp];
    self.configuration = [[VSLAccountConfiguration alloc] init];
}

- (void)testCanSetUsernameOnConfiguration {
    XCTAssertNoThrow(self.configuration.sipAccount = @"1234", @"should be able to setup a username");
}

- (void)testCanSetPasswordOnConfiguration {
    XCTAssertNoThrow(self.configuration.sipPassword = @"password", @"should be able to setup a password");
}

- (void)testAddressShouldBeEmptyOnDefault {
    XCTAssertNil(self.configuration.sipAddress, @"there should be no address on default");
}

- (void)testCanSetDomainOnConfiguration {
    XCTAssertNoThrow(self.configuration.sipDomain = @"sip.test.com", @"should be able to setup a domain");
}

- (void)testAddressShouldBeEmptyIfNoUsername {
    self.configuration.sipDomain = @"sip.test.nl";
    XCTAssertNil(self.configuration.sipAddress, @"there should be no address if there is no username");
}

- (void)testAddressShouldBeEmptyIfNoDomain {
    self.configuration.sipAccount = @"1234";
    XCTAssertNil(self.configuration.sipAddress, @"there should be no address if there is no domain");
}

- (void)testAddressShouldBeCorrectIfUsernameAndDomainAreSet {
    self.configuration.sipAccount= @"1234";
    self.configuration.sipDomain = @"sip.test.nl";
    XCTAssertEqualObjects(self.configuration.sipAddress, @"1234@sip.test.nl", @"the address should be correct if there is a domain and username");
}

- (void)testCanSetProxyOnConfiguration {
    XCTAssertNoThrow(self.configuration.sipProxyServer = @"sip.test.com", @"should be able to setup a proxy");
}

- (void)testConfigHasDefaultRealm {
    XCTAssertEqual(self.configuration.sipAuthRealm, @"*", @"The default realm should have been set");
}

- (void)testConfigHasDefaultAuthScheme {
    XCTAssertEqual(self.configuration.sipAuthScheme, @"digest", @"The default digest should have been set");
}

- (void)testConfigurationWillNotRegisterOnDefault {
    XCTAssertFalse(self.configuration.sipRegisterOnAdd, @"Config should not register on default");
}

- (void)testConfigurationWillNotPublishOnDefault {
    XCTAssertFalse(self.configuration.sipPublishEnabled, @"Config should not publish on default");
}

@end
