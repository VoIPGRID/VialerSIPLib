//
//  VSLRingtone.m
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//  Code based on https://github.com/petester42/swig/blob/master/Pod/Classes/Call/SWRingtone.m
//

#import "VSLRingtone.h"

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "Constants.h"
#import "VSLLogging.h"
#import <UIKit/UIKit.h>

static NSUInteger const VialerSIPLibVibrateDuration = 1;

@interface VSLRingtone()

@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) NSTimer *vibrateTimer;
@property (strong, nonatomic) NSURL *fileURL;

@end

@implementation VSLRingtone

- (instancetype)initWithRingtonePath:(NSURL *)ringtonePath {
    if (self = [super init]) {
        if (!ringtonePath) {
            return nil;
        }
        self.fileURL = ringtonePath;
    }
    return self;
}

- (NSTimer *)vibrateTimer {
    if (!_vibrateTimer) {
        _vibrateTimer = [NSTimer timerWithTimeInterval:VialerSIPLibVibrateDuration target:self selector:@selector(vibrate) userInfo:nil repeats:YES];
    }
    return _vibrateTimer;
}

- (AVAudioPlayer *)audioPlayer {
	if (!_audioPlayer) {
        NSError *error;
		_audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:self.fileURL error:&error];
        _audioPlayer.numberOfLoops = -1;
        if (error) {
            VSLLogError(@"Audioplayer: %@", [error description]);
        }
	}
	return _audioPlayer;
}

- (void)dealloc {
    [self.audioPlayer stop];
    self.audioPlayer = nil;

    [self.vibrateTimer invalidate];
    self.vibrateTimer = nil;
}

- (BOOL)isPlaying {
    return self.audioPlayer.isPlaying;
}

- (void)start {
    if (!self.isPlaying) {
        [self.audioPlayer prepareToPlay];
        [self configureAudioSessionBeforeRingtoneIsPlayed];
        [self.audioPlayer play];

        [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
        [[NSRunLoop mainRunLoop] addTimer:self.vibrateTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)stop {
    if (self.isPlaying) {
        [self.audioPlayer stop];
        [self.vibrateTimer invalidate];
    }
    [self.audioPlayer setCurrentTime:0];
    [self configureAudioSessionAfterRingtoneStopped];
}

- (void)vibrate {
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
}

- (void)configureAudioSessionBeforeRingtoneIsPlayed {
    VSLLogVerbose(@"Configuring Audio before playing ringtone");
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];

    // Set the audio session category. The category that is set repects the silent switch.
    NSError *setCategoryError;
    BOOL setCategorySuccess = [audioSession setCategory:AVAudioSessionCategorySoloAmbient
                                                  error:&setCategoryError];
    if (!setCategorySuccess) {
        if (setCategoryError != NULL) {
            VSLLogWarning(@"Error setting audioplayer category: %@", setCategoryError);
        }
    }

    // Temporarily changes the current audio route. We will not override the output port and let the
    // system default handle the outputs.
    NSError *overrideOutputAudioPortError;
    BOOL overrideOutputAudioPortSuccess = [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideNone
                                                                          error:&overrideOutputAudioPortError];
    if (!overrideOutputAudioPortSuccess) {
        if (overrideOutputAudioPortError != NULL) {
            VSLLogWarning(@"Error overriding audio port: %@", overrideOutputAudioPortError);
        }
    }

    // Activate the audio session.
    NSError *setActiveError;
    BOOL setActiveSuccess = [audioSession setActive:YES error:&setActiveError];
    if (!setActiveSuccess) {
        if (setActiveError != NULL) {
            VSLLogWarning(@"Error activatiing audio: %@", setActiveError);
        }
    }
}

- (void)configureAudioSessionAfterRingtoneStopped {
    VSLLogVerbose(@"Configuring Audio after ringtone has stoped");
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];

    // Set the audio session category. The category that is set is able to handle VoIP calls.
    NSError *setCategoryError;
    BOOL setCategorySuccess = [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                                                  error:&setCategoryError];
    if (!setCategorySuccess) {
        if (setCategoryError != NULL) {
            VSLLogWarning(@"Error setting audioplayer category: %@", setCategoryError);
        }
    }
}

@end
