//
//  VSLOpusConfiguration.h
//  Copyright © 2018 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, VSLOpusConfigurationSampleRate) {
    VSLOpusConfigurationSampleRateFullBand = 48000,
    VSLOpusConfigurationSampleRateSuperWideBand = 24000,
    VSLOpusConfigurationSampleRateWideBand = 16000,
    VSLOpusConfigurationSampleRateMediumBand = 12000,
    VSLOpusConfigurationSampleRateNarrowBand = 8000
};

typedef NS_ENUM(NSUInteger, VSLOpusConfigurationFrameDuration) {
    VSLOpusConfigurationFrameDurationFive = 5,
    VSLOpusConfigurationFrameDurationTen = 10,
    VSLOpusConfigurationFrameDurationTwenty = 20,
    VSLOpusConfigurationFrameDurationForty = 40,
    VSLOpusConfigurationFrameDurationSixty = 60
};

/**
 *  OPUS configuration for more explanation read the RFC at https://tools.ietf.org/html/rfc6716
 */
@interface VSLOpusConfiguration : NSObject

/**
 * Sample rate in Hz
 *
 *  Default: VSLOpusConfigurationSampleRateFullBand (48000 hz)
 */
@property (nonatomic) VSLOpusConfigurationSampleRate sampleRate;

/**
 *  The frame size of the packets being sent over.
 *
 *  Default: VSLOpusConfigurationFrameDurationSixty (60 msec)
 */
@property (nonatomic) VSLOpusConfigurationFrameDuration frameDuration;

/**
 *  Encoder complexity, 0-10 (10 is highest) 
 *
 *  Default: 5
 */
@property (nonatomic) NSUInteger complexity;

/**
 *  YES for Constant bitrate (CBR) and no to use Variable bitrate (VBR)
 *
 *  Set to YES for:
 *      - When the transport only supports a fixed size for each compressed frame, or
 *      - When encryption is used for an audio stream that is either highly constrained (e.g., yes/no, recorded prompts) or highly sensitive
 *
 *  Default: NO
 */
@property (nonatomic) BOOL constantBitRate;

@end
