//
//  VSLCallViewController.m
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import <CocoaLumberJack/CocoaLumberjack.h>
#import "VSLCallViewController.h"
#import <VialerSIPLib-iOS/VSLRingtone.h>

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

@interface VSLCallViewController ()
@property (weak, nonatomic) IBOutlet UILabel *numbersPressedLabel;
@property (weak, nonatomic) IBOutletCollection(UIButton) NSArray *keypadNumbers;
@end

@implementation VSLCallViewController

#pragma mark - properties

- (void)setNumberToCall:(NSString *)numberToCall {
    [self.account callNumber:numberToCall withCompletion:^(NSError *error, VSLCall *call) {
        [UIDevice currentDevice].proximityMonitoringEnabled = YES;
        if (error) {
            DDLogError(@"%@", error);
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
    [self updateUIForCall];
    [call addObserver:self forKeyPath:@"callState" options:0 context:NULL];
    [call addObserver:self forKeyPath:@"mediaState" options:0 context:NULL];
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
}

- (IBAction)keyPadNumberPressed:(UIButton *)sender {
    self.numbersPressedLabel.text = [NSString stringWithFormat:@"%@%@", self.numbersPressedLabel.text, sender.currentTitle];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {

    if (object == self.call) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateUIForCall];
            if (self.call.callState == VSLCallStateDisconnected) {
                [self.call removeObserver:self forKeyPath:@"callState"];
                [self.call removeObserver:self forKeyPath:@"mediaState"];
                self.delegate.call = self.call;
                [UIDevice currentDevice].proximityMonitoringEnabled = NO;
                [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
            }
        });
    }
}

- (void)updateUIForCall {

}

@end
