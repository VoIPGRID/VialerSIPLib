//
//  VSLCodecConfiguration.h
//  Copyright © 2018 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VSLAudioCodecs;
@class VSLVideoCodecs;

@interface VSLCodecConfiguration : NSObject

/**
 * An array of available audio codecs.
 */
@property (strong, nonatomic) NSArray* audioCodecs;

/**
 * An array of available video codecs.
 */
@property (strong, nonatomic) NSArray* videoCodecs;

@end
