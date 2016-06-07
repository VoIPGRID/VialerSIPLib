//
//  VSLViewController.m
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import "VSLViewController.h"

#import "AppDelegate.h"
#import <CocoaLumberJack/CocoaLumberjack.h>
#import "Keys.h"
#import "SipUser.h"
#import <VialerSIPLib-iOS/VSLRingtone.h>
#import <VialerSIPLib-iOS/VSLEndpoint.h>
#import "VSLCallViewController.h"

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
static NSString * const VSLViewControllerMakeCallSegue = @"MakeCallSegue";
static NSString * const VSLViewControllerAcceptCallSegue = @"AcceptCallSegue";

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
@property (weak, nonatomic) IBOutlet UIButton *acceptCallButton;
@property (weak, nonatomic) IBOutlet UIButton *declineCallButton;
@property (weak, nonatomic) IBOutlet UIButton *makeCallButton;
@property (weak, nonatomic) IBOutlet UIButton *iLBCButton;

@property (weak, nonatomic) IBOutlet UIButton *registerAccountButton;

@property (strong, nonatomic) VSLAccount *account;
@property (strong, nonatomic) VSLRingtone *ringtone;
@property (nonatomic) BOOL useILBC;
@end

@implementation VSLViewController

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.numberToCall.text = KeysNumberToCall;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(incomingCallNotification:) name:AppDelegateIncominCallNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(handleEnteredBackground:) name: UIApplicationDidEnterBackgroundNotification object:nil];

    if (self.call) {
        [self updateUIForCall];
    }
}

#pragma mark - Properties

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

- (VSLRingtone *)ringtone {
    if (!_ringtone) {
        NSURL *fileUrl = [[NSBundle mainBundle] URLForResource:@"ringtone" withExtension:@"wav"];
        _ringtone = [[VSLRingtone alloc] initWithRingtonePath:fileUrl];
    }
    return _ringtone;
}

#pragma mark - Actions

- (IBAction)toggleRegisterAccount:(UIButton *)sender {
    if (self.account) {
        if([self.account unregisterAccount:nil]) {
            [self.account removeObserver:self forKeyPath:@"accountState"];
            self.account = nil;
            [self updateUIForCall];
        }
    } else {
        self.registerAccountButton.enabled = NO;
        SipUser *testUser = [[SipUser alloc] init];
        testUser.sipAccount = KeysAccount;
        testUser.sipPassword = KeysPassword;
        testUser.sipDomain = KeysDomain;
        testUser.sipProxy = KeysProxy;

        NSError *error;
        [[VialerSIPLib sharedInstance] registerAccountWithUser:testUser withCompletion:^(BOOL success, VSLAccount * _Nullable account) {
            self.registerAccountButton.enabled = YES;
            [self updateUIForCall];
            if (!success) {
                if (error != NULL) {
                    DDLogError(@"%@", error);
                }
            } else {
                self.account = account;
                NSLog(@"%@", account);
                [self.account addObserver:self forKeyPath:@"accountState" options:0 context:NULL];
            }
        }];
    }
}

- (IBAction)decline:(UIButton *)sender {
    NSError *error;
    [self.call decline:&error];
    if (error) {
        DDLogError(@"Error declining the call: %@", error);
    }
}

- (IBAction)toggleILBC:(UIButton *)sender {
    self.useILBC = !self.useILBC;
    [[VSLEndpoint sharedEndpoint] onlyUseILBC:self.useILBC];

    DDLogInfo(self.useILBC ? @"YES": @"NO");
    [self.iLBCButton setTitle:(self.useILBC ? @"Turn off iLBC" : @"Use iLBC") forState:UIControlStateNormal];
}

#pragma mark - Segues

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:VSLViewControllerAcceptCallSegue]) {
        [self.ringtone stop];
        NSError *error;
        [self.call answer:&error];
        if (error) {
            DDLogError(@"Error accepting call: %@", error);
            return NO;
        }
        [UIDevice currentDevice].proximityMonitoringEnabled = YES;
        return YES;
    }
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:VSLViewControllerMakeCallSegue]) {
        VSLCallViewController *cvc = (VSLCallViewController *)segue.destinationViewController;
        cvc.delegate = self;
        cvc.account = self.account;
        cvc.numberToCall = self.numberToCall.text;
    } else if ([segue.identifier isEqualToString:VSLViewControllerAcceptCallSegue]) {
        VSLCallViewController *cvc = (VSLCallViewController *)segue.destinationViewController;
        cvc.delegate = self;
        cvc.account = self.account;
        cvc.call = self.call;
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {

    if (object == self.call) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateUIForCall];
            if (self.call.callState == VSLCallStateDisconnected) {
                [UIDevice currentDevice].proximityMonitoringEnabled = NO;
                [self.ringtone stop];
                [self updateUIForCall];
            }
        });
    }
    if (object == self.account) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateUIForCall];
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

    self.acceptCallButton.enabled = self.call && self.call.callState != VSLCallStateDisconnected ? YES: NO;
    self.declineCallButton.enabled = self.call && self.call.callState != VSLCallStateDisconnected ? YES: NO;

    [self.registerAccountButton setTitle:self.account.isRegistered ? @"Unregister" : @"Register" forState:UIControlStateNormal];
    self.accountStateLabel.text = [NSString stringWithFormat:@"%ld", (long)self.account.accountState];
}

- (void)handleEnteredBackground:(NSNotification *)notification {
    [self.ringtone stop];
    if (self.call) {
        NSError *error;
        [self.call hangup:&error];
        if (error) {
            DDLogError(@"Error hangup call: %@", error);
        } else {
            self.call = nil;
        }
    }
}

- (void)incomingCallNotification:(NSNotification *)notification {
    VSLCall *call = (VSLCall *)notification.object;

    // Check state of current call.
    if (self.call && self.call.callState != VSLCallStateDisconnected) {
        // Not able to accept this call, decline/hangup.
        [call hangup:nil];
    } else {
        [self dismissViewControllerAnimated:NO completion:nil];
        self.call = call;
        [self.ringtone start];
    }
}

@end
