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

@end

@implementation VSLViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)makeCall:(id)sender {
    SipUser *testUser = [[SipUser alloc] init];
    testUser.sipUsername = KeysUsername;
    testUser.sipPassword = KeysPassword;
    testUser.sipDomain = KeysDomain;
    testUser.sipProxy = KeysProxy;
    testUser.sipRegisterOnAdd = YES;
    [[VialerSIPLib sharedInstance] callNumber:self.numberToCall.text withSipUser:testUser withCompletion:^(VSLCall *outboundCall, NSError *error) {
        if (error) {
            DDLogError(@"%@", error);
        } else {
            DDLogInfo(@"Calling number....");
        }
    }];
}

- (IBAction)endCall:(id)sender {
    [[VialerSIPLib sharedInstance] hangup];
}

@end
