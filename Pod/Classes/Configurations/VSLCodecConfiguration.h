//
//  VSLCodecConfiguration.h
//  Copyright © 2018 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VSLAudioCodecs.h"
#import "VSLVideoCodecs.h"
#import "VSLOpusConfiguration.h"

@interface VSLCodecConfiguration : NSObject

/**
 * An array of available audio codecs.
 */
@property (strong, nonatomic) NSArray * _Nullable audioCodecs;

/**
 * An array of available video codecs.
 */
@property (strong, nonatomic) NSArray * _Nullable videoCodecs;

/**
 *  The linked OPUS configuration when opus is being used.
 */
@property (nonatomic) VSLOpusConfiguration * _Nullable opusConfiguration;

@end
