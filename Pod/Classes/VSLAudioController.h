//
//  VSLAudioController.h
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * __nonnull const VSLAudioControllerAudioInterrupted;
extern NSString * __nonnull const VSLAudioControllerAudioResumed;

@interface VSLAudioController : NSObject

/**
 *  Configure audio.
 */
- (void)configureAudioSession;

/**
 *  Activate the audio session.
 */
- (void)activateAudioSession;

/**
 *  Deactivate the audio session.
 */
- (void)deactivateAudioSession;
@end
