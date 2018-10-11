//
//  VSLEndPointConfiguration.m
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import "VSLEndpointConfiguration.h"

#import <VialerPJSIP/pjsua.h>
#import "VSLTransportConfiguration.h"

static NSUInteger const VSLEndpointConfigurationMaxCalls = 4;
static NSUInteger const VSLEndpointConfigurationLogLevel = 5;
static NSUInteger const VSLEndpointConfigurationLogConsoleLevel = 4;
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
        self.disableVideoSupport = NO;
        self.unregisterAfterCall = NO;
    }
    return self;
}

- (NSArray *)transportConfigurations {
    if (!_transportConfigurations) {
        _transportConfigurations = [NSArray array];
    }
    return _transportConfigurations;
}

- (VSLIpChangeConfiguration *)ipChangeConfiguration {
    if (!_ipChangeConfiguration) {
        _ipChangeConfiguration = [[VSLIpChangeConfiguration alloc] init];
    }
    return _ipChangeConfiguration;
}

- (VSLStunConfiguration *)stunConfiguration {
    if (!_stunConfiguration) {
        _stunConfiguration = [[VSLStunConfiguration alloc] init];
    }
    return _stunConfiguration;
}

- (VSLCodecConfiguration *)codecConfiguration {
    if (!_codecConfiguration) {
        _codecConfiguration = [[VSLCodecConfiguration alloc] init];
    }
    return _codecConfiguration;
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

- (BOOL)hasTLSConfiguration {
    NSUInteger index = [self.transportConfigurations indexOfObjectPassingTest:^BOOL(VSLTransportConfiguration *transportConfiguration, NSUInteger idx, BOOL *stop) {
        if (transportConfiguration.transportType == VSLTransportTypeTLS || transportConfiguration.transportType == VSLTransportTypeTLS6) {
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

-(BOOL)hasUDPConfiguration {
    NSUInteger index = [self.transportConfigurations indexOfObjectPassingTest:^BOOL(VSLTransportConfiguration *transportConfiguration, NSUInteger idx, BOOL *stop) {
        if (transportConfiguration.transportType == VSLTransportTypeUDP || transportConfiguration.transportType == VSLTransportTypeUDP6) {
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
