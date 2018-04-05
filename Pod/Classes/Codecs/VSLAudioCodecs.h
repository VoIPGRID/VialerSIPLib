//
//  VSLCodecs.h
//  Copyright © 2018 Devhouse Spindle. All rights reserved.
//


#import <Foundation/Foundation.h>

#import "VSLCodecConfiguration.h"

/**
 *  Enum of possible Audio Codecs.
 */
typedef NS_ENUM(NSInteger, VSLAudioCodec) {
        // G711a
    VSLAudioCodecG711a,
        // G722
    VSLAudioCodecG722,
        // iLBC
    VSLAudioCodecILBC,
        // G711
    VSLAudioCodecG711,
        // Speex 8 kHz
    VSLAudioCodecSpeex8000,
        // Speex 16 kHz
    VSLAudioCodecSpeex16000,
        // Speex 32 kHz
    VSLAudioCodecSpeex32000,
        // GSM 8 kHZ
    VSLAudioCodecGSM,
        // Opus
    VSLAudioCodecOpus,
};
#define VSLAudioCodecString(VSLAudioCodec) [VSLAudioCodecArray objectAtIndex:VSLAudioCodec]
#define VSLAudioCodecStringWithIndex(NSInteger) [VSLAudioCodecArray objectAtIndex:NSInteger]
#define VSLAudioCodecArray @[@"PCMA/8000/1", @"G722/16000/1", @"iLBC/8000/1", @"PCMU/8000/1", @"speex/8000/1", @"speex/16000/1", @"speex/32000/1", @"GSM/8000/1", @"opus/48000/2"]


@interface VSLAudioCodecs : NSObject

/**
 *  The prioritiy of the codec
 */
@property (readonly, nonatomic) NSUInteger priority;

/**
 * The used codec.
 */
@property (readonly, nonatomic) VSLAudioCodec codec;

/**
 * Make the default init unavaibale.
 */
- (instancetype _Nonnull) init __attribute__((unavailable("init not available. Use initWithAudioCodec instead.")));

/**
 * The init to setup the audio codecs.
 *
 * @param codec     Audio codec codec to set the prioritiy for.
 * @param priority  NSUInteger the priority the codec will have.
 */
- (instancetype _Nonnull)initWithAudioCodec:(VSLAudioCodec)codec andPriority:(NSUInteger)priority;

/**
 * Get the codec from the #define VSLCodecConfigurationAudioString with a VSLCodecConfigurationAudio type.
 *
 * @param codec VSLCodecConfigurationAudio the codec to get the string representation of.
 *
 * @return NSString the string representation of the VSLCodecConfigurationAudio type.
 */
+ (NSString * _Nonnull)codecString:(VSLAudioCodec)codec;

/**
 * Get the codec from the defined VSLCodecConfigurationAudioString with an index.
 */
+ (NSString * _Nonnull)codecStringWithIndex:(NSInteger)index;

@end
