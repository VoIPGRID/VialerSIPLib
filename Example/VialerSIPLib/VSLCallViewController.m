//
//  VSLCallViewController.m
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <CocoaLumberJack/CocoaLumberjack.h>
#import "VSLCallViewController.h"
#import <VialerSIPLib-iOS/VSLRingtone.h>

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

static const NSTimeInterval statsInterval = 1.0;

@interface VSLCallViewController ()
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *keypadNumbers;
@property (weak, nonatomic) IBOutlet UILabel *numbersPressedLabel;
@property (strong, nonatomic) NSString *currentAudioSessionCategory;
@property (weak, nonatomic) IBOutlet UILabel *dataLabel;
@property (weak, nonatomic) IBOutlet UILabel *rLabel;
@property (weak, nonatomic) IBOutlet UILabel *mosLabel;
@property (weak, nonatomic) IBOutlet UILabel *callTimeLabel;
@property (strong, nonatomic) NSTimer * statsTimer;
@property (strong, nonatomic) NSDate * startDateCall;
@end

@implementation VSLCallViewController

#pragma mark - properties

- (void)setNumberToCall:(NSString *)numberToCall {
    self.currentAudioSessionCategory = [AVAudioSession sharedInstance].category;
    [self.account callNumber:numberToCall withCompletion:^(NSError *error, VSLCall *call) {
        [UIDevice currentDevice].proximityMonitoringEnabled = YES;
        if (error) {
            DDLogError(@"%@", error);
            NSError *setAudioSessionCategoryError;
            [[AVAudioSession sharedInstance] setCategory:self.currentAudioSessionCategory error:&error];
            if (setAudioSessionCategoryError) {
                DDLogError(@"Error setting the audio session category: %@", setAudioSessionCategoryError);
            }
        } else {
            self.call = call;
        }
    }];
}

- (void)setCall:(VSLCall *)call {
    if (_call) {
        [_call removeObserver:self forKeyPath:@"callState"];
        [_call removeObserver:self forKeyPath:@"mediaState"];
    }
    _call = call;
    [call addObserver:self forKeyPath:@"callState" options:0 context:NULL];
    [call addObserver:self forKeyPath:@"mediaState" options:0 context:NULL];
    self.currentAudioSessionCategory = [AVAudioSession sharedInstance].category;
    self.statsTimer = [NSTimer scheduledTimerWithTimeInterval:statsInterval target:self selector:@selector(getStats) userInfo:nil repeats:YES];
}

#pragma mark - Actions

- (IBAction)keypad:(id)sender {
    for (UIButton *button in self.keypadNumbers) {
        button.hidden = !button.hidden;
    }
}

- (IBAction)toggleMuteCall:(UIButton *)sender {
    [self.call toggleMute:nil];
}

- (IBAction)toggleSpeaker:(UIButton *)sender {
    [self.call toggleSpeaker];
}

- (IBAction)toggleHold:(UIButton *)sender {
    [self.call toggleHold:nil];
}

- (IBAction)endCall:(id)sender {
    NSError *error;
    [self.call hangup:&error];
    self.numbersPressedLabel.text = @"";

    if (error) {
        DDLogError(@"Error hangup call: %@", error);
    }

    NSError *setAudioSessionCategoryError;
    [[AVAudioSession sharedInstance] setCategory:self.currentAudioSessionCategory error:&setAudioSessionCategoryError];
    if (setAudioSessionCategoryError) {
        DDLogError(@"Error setting the audio session category: %@", setAudioSessionCategoryError);
    }
}

- (IBAction)keyPadNumberPressed:(UIButton *)sender {
    self.numbersPressedLabel.text = [NSString stringWithFormat:@"%@%@", self.numbersPressedLabel.text, sender.currentTitle];
    NSError *error;
    [self.call sendDTMF:sender.currentTitle error:&error];
    if (error) {
        DDLogError(@"Error sending DTMF signal: %@", error);
    }
}

- (void)getStats {
    if (self.call.callState == VSLCallStateConfirmed) {
        [self.call calculateStats];
        self.dataLabel.text = [NSString stringWithFormat:@"%.3f MB", self.call.totalMBsUsed];
        self.rLabel.text = [NSString stringWithFormat:@"%.1f", self.call.R];
        self.mosLabel.text = [NSString stringWithFormat:@"%.1f", self.call.MOS];
        self.callTimeLabel.text = [NSString stringWithFormat:@"%.0f", -[self.startDateCall timeIntervalSinceNow]];
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {

    if (object == self.call) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.call.callState == VSLCallStateConfirmed) {
                self.startDateCall = [NSDate date];
            }
            if (self.call.callState == VSLCallStateDisconnected) {
                [self.statsTimer invalidate];
                @try {
                    [self.call removeObserver:self forKeyPath:@"callState"];
                } @catch (NSException *exception) {
                    DDLogInfo(@"Observer for keyPath callState was already removed. %@", exception);
                }

                @try {
                    [self.call removeObserver:self forKeyPath:@"mediaState"];
                } @catch (NSException *exception) {
                    DDLogInfo(@"Observer for keyPath mediaState was already removed. %@", exception);
                }

                self.delegate.call = self.call;
                [UIDevice currentDevice].proximityMonitoringEnabled = NO;
                [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
            }
        });
    }
}

@end
