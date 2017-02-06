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
    VSLCodecOpus
};
#define VSLCodecString(VSLCodec) [@[@"PCMA/8000/1", @"G722/16000/1", @"iLBC/8000/1", @"PCMU/8000/1", @"speex/8000/1", @"speex/16000/1", @"speex/32000/1", @"GSM/8000/1", @"opus/48000/2"] objectAtIndex:VSLCodec]

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

@end
