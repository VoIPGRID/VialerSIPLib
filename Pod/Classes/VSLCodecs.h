//
//  VSLCodecs.h
//  Copyright © 2017 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VSLCodecs : NSObject

/**
 * Enum of codecs that can be supported.
 */
typedef NS_ENUM(NSInteger, VSLCodec) {
    // G711a
    VSLCodecG711a,
    // G722
    VSLCodecG722,
    // iLBC
    VSLCodecILBC,
    // G711
    VSLCodecG711,
    // Speex 8 kHz
    VSLCodecSpeex8000,
    // Speex 16 kHz
    VSLCodecSpeex16000,
    // Speex 32 kHz
    VSLCodecSpeex32000,
    // GSM 8 kHZ
    VSLCodecGSM,
    // Opus
    VSLCodecOpus,
    // H264 - Video codec
    VSLCodecH264
};
#define VSLCodecString(VSLCodec) [VSLCodecsArray objectAtIndex:VSLCodec]
#define VSLCodecStringWithIndex(NSInteger) [VSLCodecsArray objectAtIndex:NSInteger]
#define VSLCodecsArray @[@"PCMA/8000/1", @"G722/16000/1", @"iLBC/8000/1", @"PCMU/8000/1", @"speex/8000/1", @"speex/16000/1", @"speex/32000/1", @"GSM/8000/1", @"opus/48000/2", @"H264/97"]

/**
 *  The prioritiy of the codec
 */
@property (readonly, nonatomic) NSUInteger priority;

/**
 * The used codec.
 */
@property (readonly, nonatomic) VSLCodec codec;

/**
 * Make the default init unavaibale.
 */
- (instancetype _Nonnull) init __attribute__((unavailable("init not available. Use initWithCodec instead.")));

/**
 * The init to setup the codecs.
 *
 * @param codec     VSLCodec the codec to set the prioritiy for.
 * @param priority  NSUInteger the priority the codec will have.
 */
- (instancetype)initWithCodec:(VSLCodec)codec andPriotity:(NSUInteger)priority;

/**
 * Update the codecs priority for the codec negotiation when setting up a call.
 *
 * @param codecsToUse NSArray array of codecs to use with the priority set.
 *
 * @return BOOL true when updating the codecs priority was a success.
 */
+ (BOOL)updateCodecs:(NSArray * _Nonnull)codecsToUse;

/**
 * Get the codec from the #define VSLCodecString with a VSLCodec type.
 *
 * @param codec VSLCodec the codec to get the string representation of.
 *
 * @return NSString the string representation of the VSLCodec type.
 */
+ (NSString *)codecString:(VSLCodec)codec;

/**
 * Get the codec from the defined string with an index.
 */
+ (NSString *)codecStringWithIndex:(NSInteger)index;

/**
 * Get the number of codecs that can be used.
 */
+ (NSInteger)numberOfCodecs;

/**
 * MutableArray of the codecs that are available.
 */
+ (NSArray *)codecsArray;
@end
