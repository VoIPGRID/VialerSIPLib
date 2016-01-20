//
//  VSLViewController.m
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import "VSLViewController.h"

#import <CocoaLumberJack/CocoaLumberjack.h>
#import "Keys.h"
#import "SipUser.h"
#import <VialerSIPLib-iOS/VialerSIPLib.h>

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

@interface VSLViewController ()
@property (weak, nonatomic) IBOutlet UITextField *numberToCall;
@property (weak, nonatomic) IBOutlet UILabel *callStateLabel;
@property (weak, nonatomic) IBOutlet UILabel *callStateTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *mediaStateLabel;
@property (weak, nonatomic) IBOutlet UILabel *callIdLabel;
@property (weak, nonatomic) IBOutlet UILabel *accountIdLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastStatusTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *localUriLabel;
@property (weak, nonatomic) IBOutlet UILabel *remoteUriLabel;
@property (weak, nonatomic) IBOutlet UILabel *incomingLabel;
@property (weak, nonatomic) IBOutlet UILabel *accountStateLabel;

@property (strong, nonatomic) VSLCall *call;
@property (strong, nonatomic) VSLAccount *account;
@end

@implementation VSLViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (VSLAccount *)account {
    if (!_account) {
        _account = [[VialerSIPLib sharedInstance] firstAccount];
    }
    return _account;
}

- (IBAction)makeCall:(id)sender {
    [self.account callNumber:self.numberToCall.text withCompletion:^(NSError *error, VSLCall *call) {
        if (error) {
            DDLogError(@"%@", error);
        } else {
            [UIDevice currentDevice].proximityMonitoringEnabled = YES;
            self.call = call;
            [self updateUIForCall];
            [call addObserver:self forKeyPath:@"callState" options:0 context:NULL];
            [call addObserver:self forKeyPath:@"mediaState" options:0 context:NULL];
        }
    }];
}

- (IBAction)registerAccount:(id)sender {
    [self.account addObserver:self forKeyPath:@"accountState" options:0 context:NULL];

    SipUser *testUser = [[SipUser alloc] init];
    testUser.sipUsername = KeysUsername;
    testUser.sipPassword = KeysPassword;
    testUser.sipDomain = KeysDomain;
    testUser.sipProxy = KeysProxy;

    NSError *error;
    BOOL success = [[VialerSIPLib sharedInstance] registerAccount:testUser error:&error];

    if (success && error == nil) {
        [[VialerSIPLib sharedInstance] setIncomingCallBlock:^(VSLCall * _Nonnull call) {
            DDLogInfo(@"Incoming call");
        }];
    } else {
        DDLogError(@"%@", error);
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {

    if (object == self.call) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateUIForCall];
            if (self.call.callState == VSLCallStateDisconnected) {
                [UIDevice currentDevice].proximityMonitoringEnabled = NO;
            }
        });
    }
    if (object == self.account) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.accountStateLabel.text = [NSString stringWithFormat:@"%ld", (long)self.account.accountState];
        });
    }
}

- (void)updateUIForCall {
    self.callStateLabel.text = [NSString stringWithFormat:@"%d", (int)self.call.callState];
    self.callStateTextLabel.text = self.call.callStateText;
    self.mediaStateLabel.text = [NSString stringWithFormat:@"%d", (int)self.call.mediaState];
    self.callIdLabel.text = [NSString stringWithFormat:@"%d", (int)self.call.callId];
    self.accountIdLabel.text = [NSString stringWithFormat:@"%d", (int)self.call.accountId];
    self.lastStatusLabel.text = [NSString stringWithFormat:@"%d", (int)self.call.lastStatus];
    self.lastStatusTextLabel.text = self.call.lastStatusText;
    self.localUriLabel.text = self.call.localURI;
    self.remoteUriLabel.text = self.call.remoteURI;
    self.incomingLabel.text = self.call.incoming ? @"YES": @"NO";
}

- (IBAction)endCall:(id)sender {
    NSError *error;
    [self.call hangup:&error];
    if (error) {
        DDLogError(@"Error hangup call: %@", error);
    }
}

@end
