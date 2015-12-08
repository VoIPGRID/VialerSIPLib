//
//  VSLTransportConfigurationTests.m
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import <VSLTransportConfiguration.h>
#import <XCTest/XCTest.h>

@interface VSLTransportConfigurationTests : XCTestCase
@property (strong, nonatomic) VSLTransportConfiguration *configuration;
@end

@implementation VSLTransportConfigurationTests

- (void)setUp {
    [super setUp];
    self.configuration = [[VSLTransportConfiguration alloc] init];
}

- (void)testConfigHasADefaultPortSet {
    XCTAssertEqual(self.configuration.port, 5060, @"There should be a default sip port set");
}

- (void)testConfigHasNoDefaultPortRange {
    XCTAssertEqual(self.configuration.portRange, 0, @"There should be no range set");
}

- (void)testConfigHasADefaultConfigTransportType {
    XCTAssertEqual(self.configuration.transportType, VSLTransportTypeTCP, @"Default transport type should be UDP");
}

@end
