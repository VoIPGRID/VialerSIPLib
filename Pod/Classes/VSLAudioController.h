//
//  VSLAudioController.h
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * __nonnull const VSLAudioControllerAudioInterrupted;
extern NSString * __nonnull const VSLAudioControllerAudioResumed;

/**
 *  Possible outputs the audio can have.
 */
typedef NS_ENUM(NSInteger, VSLAudioControllerOutputs) {
    /**
     *  Audio is sent over the speaker
     */
    VSLAudioControllerOutputSpeaker,
    /**
     *  Audio is sent to the ear speaker or mini jack
     */
    VSLAudioControllerOutputOther,
    /**
     *  Audio is sent to bluetooth
     */
    VSLAudioControllerOutputBluetooth,
};
#define VSLAudioControllerOutputsString(VSLAudioControllerOutputs) [@[@"VSLAudioControllerOutputSpeaker", @"VSLAudioControllerOutputOther", @"VSLAudioControllerOutputBluetooth"] objectAtIndex:VSLAudioControllerOutputs]


@interface VSLAudioController : NSObject

/**
 *  If there is a Bluetooth headset connected, this will return YES.
 */
@property (readonly, nonatomic) BOOL hasBluetooth;

/**
 *  The current routing of the audio.
 *
 *  Attention: Possible values that can be set: VSLAudioControllerSpeaker & VSLAudioControllerOther.
 *  Setting the property to VSLAudioControllerBluetooth won't work, if you want to activatie bluetooth
 *  you have to change the route with the mediaplayer (see example app).
 */
@property (nonatomic) VSLAudioControllerOutputs output;


- (void)toggleSpeaker;

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
