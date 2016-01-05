//
//  VSLEndPointConfiguration.m
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import "VSLEndpointConfiguration.h"

#import <VialerPJSIP/pjsua.h>
#import <VialerPJSIP/pj/file_io.h>
#import "VSLTransportConfiguration.h"

static NSUInteger const VSLEndpointConfigurationMaxCalls = 4;
static NSUInteger const VSLEndpointConfigurationLogLevel = 5;
static NSUInteger const  VSLEndpointConfigurationLogConsoleLevel = 4;
static NSString * const VSLEndpointConfigurationLogFileName = nil;
static NSUInteger const VSLEndpointConfigurationClockRate = PJSUA_DEFAULT_CLOCK_RATE;
static NSUInteger const VSLEndpointConfigurationSndClockRate = 0;

@implementation VSLEndpointConfiguration

- (instancetype)init {
    if (self = [super init]) {
        self.maxCalls = VSLEndpointConfigurationMaxCalls;

        self.logLevel = VSLEndpointConfigurationLogLevel;
        self.logConsoleLevel = VSLEndpointConfigurationLogConsoleLevel;
        self.logFilename = VSLEndpointConfigurationLogFileName;
        self.logFileFlags = PJ_O_APPEND;

        self.clockRate = VSLEndpointConfigurationClockRate;
        self.sndClockRate = VSLEndpointConfigurationSndClockRate;
    }
    return self;
}

- (NSArray *)transportConfigurations {
    if (!_transportConfigurations) {
        _transportConfigurations = [NSArray array];
    }
    return _transportConfigurations;
}

- (void)setLogLevel:(NSUInteger)logLevel {
    NSAssert(logLevel > 0, @"Log level needs to be set higher than 0");
    _logLevel = logLevel;
}

- (void)setLogConsoleLevel:(NSUInteger)logConsoleLevel {
    NSAssert(logConsoleLevel > 0, @"Console log level needs to be higher than 0");
    _logConsoleLevel = logConsoleLevel;
}

- (BOOL)hasTCPConfiguration {
    NSUInteger index = [self.transportConfigurations indexOfObjectPassingTest:^BOOL(VSLTransportConfiguration *transportConfiguration, NSUInteger idx, BOOL *stop) {
        if (transportConfiguration.transportType == VSLTransportTypeTCP || transportConfiguration.transportType == VSLTransportTypeTCP6) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];

    if (index == NSNotFound) {
        return NO;
    }
    return YES;
}

@end
