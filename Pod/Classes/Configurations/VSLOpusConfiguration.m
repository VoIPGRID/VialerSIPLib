//
//  VSLOpusConfiguration.m
//  Copyright © 2018 Devhouse Spindle. All rights reserved.
//

#import "VSLOpusConfiguration.h"

static VSLOpusConfigurationSampleRate const VSLOpusConfigurationSampleRateDefault = VSLOpusConfigurationSampleRateFullBand;
static VSLOpusConfigurationFrameDuration const VSLOpusConfigurationFrameDurationDefault = VSLOpusConfigurationFrameDurationSixty;
static NSUInteger const VSLOpusConfigurationComplexity = 5;

@implementation VSLOpusConfiguration

- (instancetype)init {
    if (self = [super init]) {
        self.sampleRate = VSLOpusConfigurationSampleRateDefault;
        self.frameDuration = VSLOpusConfigurationFrameDurationDefault;
        self.constantBitRate = NO;
        self.complexity = VSLOpusConfigurationComplexity;
    }
    return self;
}

- (void)setComplexity:(NSUInteger)complexity {
    NSAssert(complexity > 0 && complexity <= 10, @"Complexity needs to be between 0 and 10");
    _complexity = complexity;
}

@end
