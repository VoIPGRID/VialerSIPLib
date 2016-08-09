//
//  VSLEndpointConfigurationTests.m
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import <VialerPJSIP/pjsua.h>
#import <VSLEndpointConfiguration.h>
#import <VSLTransportConfiguration.h>
#import <XCTest/XCTest.h>

@interface VSLEndpointConfigurationTests : XCTestCase
@property (strong, nonatomic) VSLEndpointConfiguration *configuration;
@end

@implementation VSLEndpointConfigurationTests

- (void)setUp {
    [super setUp];
    self.configuration = [[VSLEndpointConfiguration alloc] init];
}

- (void)testDefaultMaxCalls {
    XCTAssertEqual(self.configuration.maxCalls, 4, @"There should be 4 calls set as maximum");
}

- (void)testThereShouldBeADefaultLogLevel {
    XCTAssertEqual(self.configuration.logLevel, 5, @"There should be a default loglevel of 5");
}

- (void)testThereIsNoLogfilenameSetOnDefault {
    XCTAssertNil(self.configuration.logFilename, @"There is no logfilename on default");
}

- (void)testThereAreLogFileFlagsOnDefault {
    XCTAssertEqual(self.configuration.logFileFlags, PJ_O_APPEND, @"There should be a flag set");
}

- (void)testThereIsNoDefaultClockRate {
    XCTAssertEqual(self.configuration.clockRate, PJSUA_DEFAULT_CLOCK_RATE);
}

- (void)testThereIsNoDefaultSndClockRate {
    XCTAssertEqual(self.configuration.sndClockRate, 0);
}

- (void)testTransportConfigurationsIsemptyOnDefault {
    XCTAssertNotNil(self.configuration.transportConfigurations, @"There should be an array");
    XCTAssertEqual([self.configuration.transportConfigurations count], 0, @"There should be no transport configuration by default");
}

- (void)testThereIsNoDefaultTCPConfiguration {
    XCTAssertFalse([self.configuration hasTCPConfiguration], @"There should be no default tcp transport configuration");
}

- (void)testAddingAUDPTransportConfigurationGivesNoTCPConfiguration {
    VSLTransportConfiguration *transportConfig = [[VSLTransportConfiguration alloc] init];
    transportConfig.transportType = VSLTransportTypeUDP;
    self.configuration.transportConfigurations = @[transportConfig];

    XCTAssertFalse([self.configuration hasTCPConfiguration], @"There should be no tcp transport configuration");
}

- (void)testAddingATCPTransportConfigurationGivesATCPConfiguration {
    VSLTransportConfiguration *transportConfig = [[VSLTransportConfiguration alloc] init];
    transportConfig.transportType = VSLTransportTypeTCP;
    self.configuration.transportConfigurations = @[transportConfig];

    XCTAssertTrue([self.configuration hasTCPConfiguration], @"There should be a tcp transport configuration");
}

- (void)testAddingATCP6TransportConfigurationGivesATCPConfiguration {
    VSLTransportConfiguration *transportConfig = [[VSLTransportConfiguration alloc] init];
    transportConfig.transportType = VSLTransportTypeTCP6;
    self.configuration.transportConfigurations = @[transportConfig];

    XCTAssertTrue([self.configuration hasTCPConfiguration], @"There should be a tcp transport configuration");
}

- (void)testAddingMultipleTransportConfigurationGivesATCPConfiguration {
    VSLTransportConfiguration *transportConfigTCP = [[VSLTransportConfiguration alloc] init];
    transportConfigTCP.transportType = VSLTransportTypeTCP6;
    VSLTransportConfiguration *transportConfigUDP = [[VSLTransportConfiguration alloc] init];
    transportConfigUDP.transportType = VSLTransportTypeUDP;
    self.configuration.transportConfigurations = @[transportConfigUDP, transportConfigTCP];

    XCTAssertTrue([self.configuration hasTCPConfiguration], @"There should be a tcp transport configuration");
}

@end
