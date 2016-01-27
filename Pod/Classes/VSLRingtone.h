//
//  VSLRingtone.h
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//  Code based on https://github.com/petester42/swig/blob/master/Pod/Classes/Call/SWRingtone.h
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVAudioPlayer.h>

@interface VSLRingtone : NSObject

/**
 *  Determine if the ringtone is already playing.
 */
@property (readonly, nonatomic) BOOL isPlaying;

/**
 *  Make the init unavailable.
 *
 *  @return compiler error.
 */
-(instancetype _Nullable) init __attribute__((unavailable("init not available. Use initWithRingtonePath instead.")));

/**
 *  The init to set an own ringtone file.
 *
 *  @param path Ringtone path.
 *
 *  @return VSLRingtone instance.
 */
- (instancetype _Nullable)initWithRingtonePath:(NSURL * _Nonnull)ringtonePath;

/**
 *  Start playing the ringtone.
 */
- (void)start;

/**
 *  Stop playing the ringtone.
 */
- (void)stop;

@end
