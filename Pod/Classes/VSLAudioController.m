//
//  VSLAudioController.m
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import "VSLAudioController.h"

@import AVFoundation;
#import "Constants.h"
#import "VialerSIPLib.h"
#import "VSLLogging.h"

NSString * const VSLAudioControllerAudioInterrupted = @"VSLAudioControllerAudioInterrupted";
NSString * const VSLAudioControllerAudioResumed = @"VSLAudioControllerAudioResumed";

@implementation VSLAudioController

- (instancetype)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioInterruption:) name:AVAudioSessionInterruptionNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionInterruptionNotification object:nil];
}

- (BOOL)hasBluetooth {
    NSArray *availableInputs = [[AVAudioSession sharedInstance] availableInputs];

    for (AVAudioSessionPortDescription *input in availableInputs) {
        if ([input.portType isEqualToString:AVAudioSessionPortBluetoothHFP]) {
            return YES;
        }
    }
    return NO;
}

- (VSLAudioControllerOutputs)output {
    AVAudioSessionRouteDescription *route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription *output in route.outputs) {
        if ([output.portType isEqualToString:AVAudioSessionPortBluetoothHFP]) {
            return VSLAudioControllerOutputBluetooth;
        } else if ([output.portType isEqualToString:AVAudioSessionPortBuiltInSpeaker]) {
            return VSLAudioControllerOutputSpeaker;
        }
    }
    return VSLAudioControllerOutputOther;
}

- (void)setOutput:(VSLAudioControllerOutputs)output {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    if (output == VSLAudioControllerOutputSpeaker) {
        [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    } else if (output == VSLAudioControllerOutputOther) {
        [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
    }
    VSLLogVerbose(output == VSLAudioControllerOutputSpeaker ? @"Speaker modus activated": @"Speaker modus deactivated");
}

- (void)configureAudioSession {
    NSError *audioSessionCategoryError;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&audioSessionCategoryError];
    VSLLogVerbose(@"Setting AVAudioSessionCategory to \"Play and Record\"");

    if (audioSessionCategoryError) {
        VSLLogError(@"Error setting the correct AVAudioSession category");
    }

    // set the mode to voice chat
    NSError *audioSessionModeError;
    [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeVoiceChat error:&audioSessionModeError];
    VSLLogVerbose(@"Setting AVAudioSessionCategory to \"Mode Voice Chat\"");

    if (audioSessionModeError) {
        VSLLogError(@"Error setting the correct AVAudioSession mode");
    }
}

- (void)checkCurrentThreadIsRegisteredWithPJSUA {
    static pj_thread_desc a_thread_desc;
    static pj_thread_t *a_thread;
    if (!pj_thread_is_registered()) {
        pj_thread_register(NULL, a_thread_desc, &a_thread);
    }
}

- (void)activateAudioSession {
    VSLLogDebug(@"Activating audiosession");
    [self checkCurrentThreadIsRegisteredWithPJSUA];
    pjsua_set_no_snd_dev();
    pj_status_t status;
    status = pjsua_set_snd_dev(PJMEDIA_AUD_DEFAULT_CAPTURE_DEV, PJMEDIA_AUD_DEFAULT_PLAYBACK_DEV);
    if (status != PJ_SUCCESS) {
        VSLLogWarning(@"Failure in enabling sound device");
    }
}

- (void)deactivateAudioSession {
    VSLLogDebug(@"Deactivating audiosession");
    [self checkCurrentThreadIsRegisteredWithPJSUA];
    pjsua_set_no_snd_dev();
}

/**
 *  Function called on AVAudioSessionInterruptionNotification
 *
 *  The class registers for AVAudioSessionInterruptionNotification to be able to regain
 *  audio after it has been interrupted by another call or other audio event.
 *
 *  @param notification The notification which lead to this function being invoked over GCD.
 */
- (void)audioInterruption:(NSNotification *)notification {
    NSInteger avInteruptionType = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
    if (avInteruptionType == AVAudioSessionInterruptionTypeBegan) {
        [self deactivateAudioSession];
        [[NSNotificationCenter defaultCenter] postNotificationName:VSLAudioControllerAudioInterrupted
                                                            object:self
                                                          userInfo:nil];

    } else if (avInteruptionType == AVAudioSessionInterruptionTypeEnded) {
        // Resume audio
        [self activateAudioSession];
        [[NSNotificationCenter defaultCenter] postNotificationName:VSLAudioControllerAudioResumed
                                                            object:self
                                                          userInfo:nil];
    }
}

@end
