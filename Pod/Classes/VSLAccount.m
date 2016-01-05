//
//  VSLAccount.m
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import "VSLAccount.h"

#import <CocoaLumberjack/CocoaLumberjack.h>
#import "NSString+PJString.h"
#import <VialerPJSIP/pjsua.h>
#import "VSLCall.h"
#import "VSLEndpoint.h"
#import "VSLEndpointConfiguration.h"

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
static NSUInteger const VSLAccountRegistrationTimeoutInSeconds = 800;
static NSString * const VSLAccountErrorDomain = @"VialerSIPLib.VSLAccount";

@interface VSLAccount()
@property (readwrite, nonnull, nonatomic) VSLAccountConfiguration *accountConfiguration;
@property (nonatomic, strong) NSMutableArray *calls;
@end

@implementation VSLAccount

- (instancetype)init {
    if (self = [super init]) {
        self.accountId = PJSUA_INVALID_ID;
    }
    return self;
}

- (NSMutableArray *)calls {
    if (!_calls) {
        _calls = [NSMutableArray array];
    }
    return _calls;
}

- (BOOL)configureWithAccountConfiguration:(VSLAccountConfiguration * _Nonnull)accountConfiguration error:(NSError **)error {

    // If the endpoint has a tcp connection create a variable with the needed information.
    NSString *tcp = @"";
    if ([[VSLEndpoint sharedEndpoint].endpointConfiguration hasTCPConfiguration]) {
        tcp = @";transport=tcp";
    }

    pjsua_acc_config acc_cfg;
    pjsua_acc_config_default(&acc_cfg);

    // Add sip information to the pjsua account configuration.
    acc_cfg.id = [[accountConfiguration.sipAddress stringByAppendingString:tcp] prependSipUri].pjString;
    acc_cfg.reg_uri = [[accountConfiguration.sipDomain stringByAppendingString:tcp] prependSipUri].pjString;
    acc_cfg.register_on_acc_add = accountConfiguration.sipRegisterOnAdd ? PJ_TRUE : PJ_FALSE;
    acc_cfg.publish_enabled = accountConfiguration.sipPublishEnabled ? PJ_TRUE : PJ_FALSE;
    acc_cfg.reg_timeout = VSLAccountRegistrationTimeoutInSeconds;

    // Add account information to the pjsua account configuration.
    acc_cfg.cred_count = 1;
    acc_cfg.cred_info[0].scheme = accountConfiguration.sipAuthScheme.pjString;
    acc_cfg.cred_info[0].realm = accountConfiguration.sipAuthRealm.pjString;
    acc_cfg.cred_info[0].username = accountConfiguration.sipUsername.pjString;
    acc_cfg.cred_info[0].data_type = PJSIP_CRED_DATA_PLAIN_PASSWD;
    acc_cfg.cred_info[0].data = accountConfiguration.sipPassword.pjString;
    acc_cfg.proxy_cnt = 0;

    // If a proxy server is present on the account configuration add this to pjsua account configuration.
    if (accountConfiguration.sipProxyServer) {
        acc_cfg.proxy_cnt = 1;
        acc_cfg.proxy[0] = [[accountConfiguration.sipProxyServer stringByAppendingString:tcp] prependSipUri].pjString;
    }

    int accountId;
    pj_status_t status = pjsua_acc_add(&acc_cfg, PJ_TRUE, &accountId);

    if (status == PJ_SUCCESS) {
        DDLogInfo(@"Account added succesfully");
        self.accountConfiguration = accountConfiguration;
        self.accountId = accountId;
        [[VSLEndpoint sharedEndpoint] addAccount:self];
    } else {
        if (error != NULL) {
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey: NSLocalizedString(@"Could not configure VSLAccount", nil),
                                       NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"PJSIP status code: %d", nil), status],
                                       };
            *error = [NSError errorWithDomain:VSLAccountErrorDomain code:VSLAccountErrorCannotConfigureAccount userInfo:userInfo];
        }
        return NO;
    }
    return YES;
}

- (void)removeAccount {
    pj_status_t status;

    status = pjsua_acc_del((int)self.accountId);
    [[VSLEndpoint sharedEndpoint] removeAccount:self];
}

#pragma mark - Calling methods

- (void)callNumber:(NSString *)number withCompletion:(void (^)(NSError * _Nullable, VSLCall * _Nullable))completion {
    NSError *callNumberError;
    VSLCall *call = [VSLCall callNumber:number withAccount:self error:&callNumberError];
    if (callNumberError) {
        NSDictionary *userInfo = @{NSUnderlyingErrorKey : callNumberError,
                                   NSLocalizedDescriptionKey : NSLocalizedString(@"The call couldn't be setup.", nil)
                                   };
        NSError *error =  [NSError errorWithDomain:VSLAccountErrorDomain
                                              code:VSLAccountErrorFailedCallingNumber
                                          userInfo:userInfo];
        completion(error, nil);
    } else {
        completion(nil, call);
    }
}

- (void)addCall:(VSLCall *)call {
    [self.calls addObject:call];
}

- (VSLCall *)lookupCall:(NSInteger)callId {
    NSUInteger callIndex = [self.calls indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        VSLCall *call = (VSLCall *)obj;
        if (call.callId == callId && call.callId != PJSUA_INVALID_ID) {
            return YES;
        }
        return NO;
    }];

    if (callIndex != NSNotFound) {
        return [self.calls objectAtIndex:callIndex];
    } else {
        return nil;
    }
}

@end
