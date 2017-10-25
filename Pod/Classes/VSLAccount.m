//
//  VSLAccount.m
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import "VSLAccount.h"

@import CallKit;
#import "Constants.h"
#import "VSLLogging.h"
#import "NSError+VSLError.h"
#import "NSString+PJString.h"
#import "VSLCallManager.h"
#import <VialerPJSIP/pjsua.h>
#import "VSLCall.h"
#import "VSLEndpoint.h"
#import "VSLEndpointConfiguration.h"
#import "VSLLogging.h"

static NSUInteger const VSLAccountRegistrationTimeoutInSeconds = 800;
static NSString * const VSLAccountErrorDomain = @"VialerSIPLib.VSLAccount";

@interface VSLAccount()
@property (readwrite, nonnull, nonatomic) VSLAccountConfiguration *accountConfiguration;
@property (weak, nonatomic) VSLCallManager* callManager;
@property (readwrite, nonatomic) VSLAccountState accountState;
@property (copy, nonatomic) RegistrationCompletionBlock registrationCompletionBlock;
@property (assign) BOOL shouldReregister;
@property (assign) BOOL registrationInProgress;
@end

@implementation VSLAccount

- (instancetype)initPrivate {
    if (self = [super init]) {
        self.accountId = PJSUA_INVALID_ID;
    }
    return self;
}

// This should not be needed, Account should not have a reference to callManager
-(instancetype)initWithCallManager:(VSLCallManager * _Nonnull)callManager {
    if (self = [self initPrivate]) {
        self.callManager = callManager;
    }
    return self;
}

#pragma mark - Properties

- (void)setAccountState:(VSLAccountState)accountState {
    if (_accountState != accountState) {
        VSLLogDebug(@"AccountState will change from %@(%ld) to %@(%ld)", VSLAccountStateString(_accountState),
                   (long)_accountState, VSLAccountStateString(accountState), (long)accountState);
        _accountState = accountState;
    }
}

- (BOOL)isAccountValid {
    return [[NSNumber numberWithInt:pjsua_acc_is_valid((pjsua_acc_id)self.accountId)] boolValue];
}

- (NSInteger)registrationStatus {
    if (self.accountId == PJSUA_INVALID_ID) {
        return 0;
    }
    pjsua_acc_info accountInfo;
    pj_status_t status;

    status = pjsua_acc_get_info((pjsua_acc_id)self.accountId, &accountInfo);
    if (status != PJ_SUCCESS) {
        return 0;
    }
    return accountInfo.status;
}

- (NSInteger)registrationExpiresTime {
    if (self.accountId == PJSUA_INVALID_ID) {
        return -1;
    }

    pjsua_acc_info accountInfo;
    pj_status_t status;

    status = pjsua_acc_get_info((pjsua_acc_id)self.accountId, &accountInfo);
    if (status != PJ_SUCCESS) {
        return -1;
    }
    return accountInfo.expires;
}

- (BOOL)isRegistered {
    return (self.registrationStatus / 100 == 2) && (self.registrationExpiresTime > 0);
}

- (BOOL)configureWithAccountConfiguration:(VSLAccountConfiguration * _Nonnull)accountConfiguration error:(NSError **)error {

    // If the endpoint has a tcp connection create a variable with the needed information.
    NSString *transportString = @"";
    if ([[VSLEndpoint sharedEndpoint].endpointConfiguration hasTCPConfiguration]) {
        transportString = @";transport=tcp";
    }
    if ([[VSLEndpoint sharedEndpoint].endpointConfiguration hasTLSConfiguration]) {
        transportString = @";transport=tls";
    }

    pjsua_acc_config acc_cfg;
    pjsua_acc_config_default(&acc_cfg);

    // Add sip information to the pjsua account configuration.
    acc_cfg.id = [[accountConfiguration.sipAddress stringByAppendingString:transportString] prependSipUri].pjString;
    acc_cfg.reg_uri = [[accountConfiguration.sipDomain stringByAppendingString:transportString] prependSipUri].pjString;
    acc_cfg.register_on_acc_add = accountConfiguration.sipRegisterOnAdd ? PJ_TRUE : PJ_FALSE;
    acc_cfg.publish_enabled = accountConfiguration.sipPublishEnabled ? PJ_TRUE : PJ_FALSE;
    acc_cfg.reg_timeout = VSLAccountRegistrationTimeoutInSeconds;
    acc_cfg.drop_calls_on_reg_fail = accountConfiguration.dropCallOnRegistrationFailure ? PJ_TRUE : PJ_FALSE;

    // Add account information to the pjsua account configuration.
    acc_cfg.cred_count = 1;
    acc_cfg.cred_info[0].scheme = accountConfiguration.sipAuthScheme.pjString;
    acc_cfg.cred_info[0].realm = accountConfiguration.sipAuthRealm.pjString;
    acc_cfg.cred_info[0].username = accountConfiguration.sipAccount.pjString;
    acc_cfg.cred_info[0].data_type = PJSIP_CRED_DATA_PLAIN_PASSWD;
    acc_cfg.cred_info[0].data = accountConfiguration.sipPassword.pjString;
    acc_cfg.proxy_cnt = 0;
    acc_cfg.media_stun_use = accountConfiguration.mediaStunType;
    acc_cfg.sip_stun_use = accountConfiguration.sipStunType;

    acc_cfg.allow_contact_rewrite = accountConfiguration.allowContactRewrite ? PJ_TRUE : PJ_FALSE;
    acc_cfg.contact_rewrite_method = accountConfiguration.contactRewriteMethod;

    // Shutdown the old transport is no longer connected because of an ip address change.
    acc_cfg.ip_change_cfg.shutdown_tp = accountConfiguration.ipAddressChangeShutdownTransport ? PJ_TRUE : PJ_FALSE;

    // Don't hangup calls when the ip address changes.
    acc_cfg.ip_change_cfg.hangup_calls = accountConfiguration.ipAddressChangeHangupAllCalls ? PJ_FALSE : PJ_FALSE;

    // When a call is reinvited use the specified header.
    if (!accountConfiguration.ipAddressChangeHangupAllCalls) {
        acc_cfg.ip_change_cfg.reinvite_flags = PJSUA_CALL_UPDATE_CONTACT;
    }

    acc_cfg.contact_use_src_port = accountConfiguration.contactUseSrcPort ? PJ_TRUE : PJ_FALSE;
    acc_cfg.allow_via_rewrite = accountConfiguration.allowViaRewrite ? PJ_TRUE : PJ_FALSE;

    if ([[VSLEndpoint sharedEndpoint].endpointConfiguration hasTLSConfiguration]) {
        acc_cfg.srtp_secure_signaling = 1;
        acc_cfg.use_srtp = PJMEDIA_SRTP_MANDATORY;
    }

    // If a proxy server is present on the account configuration add this to pjsua account configuration.
    if (accountConfiguration.sipProxyServer) {
        acc_cfg.proxy_cnt = 1;
        acc_cfg.proxy[0] = [[accountConfiguration.sipProxyServer stringByAppendingString:transportString] prependSipUri].pjString;
    }
    
    acc_cfg.allow_contact_rewrite = accountConfiguration.allowContactRewrite;
    acc_cfg.contact_rewrite_method = accountConfiguration.contactRewriteMethod;
    acc_cfg.contact_use_src_port = accountConfiguration.contactUseSrcPort;
    acc_cfg.allow_via_rewrite = accountConfiguration.allowViaRewrite;
    
    if (accountConfiguration.turnConfiguration) {
        acc_cfg.turn_cfg_use = PJSUA_TURN_CONFIG_USE_CUSTOM;
        acc_cfg.turn_cfg.enable_turn = accountConfiguration.turnConfiguration.enableTurn;
        acc_cfg.turn_cfg.turn_server = accountConfiguration.turnConfiguration.server.pjString;
        acc_cfg.turn_cfg.turn_auth_cred.data.static_cred.username = accountConfiguration.turnConfiguration.username.pjString;
        acc_cfg.turn_cfg.turn_auth_cred.data.static_cred.data_type = accountConfiguration.turnConfiguration.passwordType;
        acc_cfg.turn_cfg.turn_auth_cred.data.static_cred.data = accountConfiguration.turnConfiguration.password.pjString;
    }
    
    if (accountConfiguration.iceConfiguration) {
        acc_cfg.ice_cfg_use = PJSUA_ICE_CONFIG_USE_CUSTOM;
        acc_cfg.ice_cfg.enable_ice = accountConfiguration.iceConfiguration.enableIce;
    }

    int accountId;
    pj_status_t status = pjsua_acc_add(&acc_cfg, PJ_TRUE, &accountId);

    if (status == PJ_SUCCESS) {
        VSLLogInfo(@"Account added succesfully");
        self.accountConfiguration = accountConfiguration;
        self.accountId = accountId;
        [[VSLEndpoint sharedEndpoint] addAccount:self];
    } else {
        if (error != NULL) {
            *error = [NSError VSLUnderlyingError:nil
               localizedDescriptionKey: NSLocalizedString(@"Could not configure VSLAccount", nil)
           localizedFailureReasonError:[NSString stringWithFormat:NSLocalizedString(@"PJSIP status code: %d", nil), status]
                           errorDomain:VSLAccountErrorDomain
                             errorCode:VSLAccountErrorCannotConfigureAccount];
        }
        return NO;
    }

    if (!accountConfiguration.sipRegisterOnAdd) {
        self.accountState = VSLAccountStateOffline;
    }

    return YES;
}

- (void)removeAccount {
    pj_status_t status;

    status = pjsua_acc_del((pjsua_acc_id)self.accountId);
    if (status != PJ_SUCCESS) {
        VSLLogError(@"Unable to remove account from sip server.");
    }
    [[VSLEndpoint sharedEndpoint] removeAccount:self];
}

- (void)registerAccountWithCompletion:(RegistrationCompletionBlock)completion {
    VSLLogDebug(@"Account valid: %@", self.isAccountValid ? @"YES": @"NO");

    pjsua_acc_info info;
    pjsua_acc_get_info((pjsua_acc_id)self.accountId, &info);

    // If pjsua_acc_info.expires == -1 the account has a registration but, as it turns out,
    // this is not a valid check whether there is a registration in progress or not, at least,
    // not wit a connection loss. So, to track a registration in progress, an ivar is used.
    if (!self.registrationInProgress && info.expires == -1) {
        self.registrationInProgress = YES;
        VSLLogVerbose(@"Sending registration for account: %@", [NSNumber numberWithInteger:self.accountId]);

        pj_status_t status;
        status = pjsua_acc_set_registration((pjsua_acc_id)self.accountId, PJ_TRUE);
        self.registrationInProgress = NO;

        if (status != PJ_SUCCESS) {
            VSLLogError(@"Account registration failed");
            NSError *error = [NSError VSLUnderlyingError:nil
                                 localizedDescriptionKey:NSLocalizedString(@"Account registration failed", nil)
                             localizedFailureReasonError:[NSString stringWithFormat:NSLocalizedString(@"PJSIP status code: %d", nil), status]
                                             errorDomain:VSLAccountErrorDomain
                                               errorCode:VSLAccountErrorRegistrationFailed];
            completion(NO, error);
        }
    } else {
        VSLLogVerbose(@"VSLAccount registered or registration in progress, cannot sent another registration");
    }

    // Check if account is connected, otherwise set completionblock.
    if (self.accountState == VSLAccountStateConnected) {
        completion(YES, nil);
    } else {
        self.registrationCompletionBlock = completion;
    }
}

- (NSString *)debugDescription {
    NSMutableString *desc = [[NSMutableString alloc] initWithFormat:@"%@\n", self];
    [desc appendFormat:@"\t ID: %d\n", (pjsua_acc_id)self.accountId];
    [desc appendFormat:@"\t State: %@(%d)\n", VSLAccountStateString(self.accountState), (int)self.accountState];
    [desc appendFormat:@"\t Registered: %@\n",self.isRegistered ? @"YES" : @"NO"];
    [desc appendFormat:@"\t Registration Status: %d\n", (int)self.registrationStatus];
    [desc appendFormat:@"\t Registration Expires: %d\n", (int)self.registrationExpiresTime];
    [desc appendFormat:@"\t Account valid %@\n", self.isAccountValid ? @"YES": @"NO"];

    return desc;
}

- (BOOL)unregisterAccount:(NSError * _Nullable __autoreleasing *)error {

    if (!self.isRegistered) {
        return YES;
    }

    pj_status_t status;
    status = pjsua_acc_set_registration((pjsua_acc_id)self.accountId, PJ_FALSE);

    if (status != PJ_SUCCESS) {
        VSLLogError(@"Account unregistration failed");
        if (error != nil) {
            *error = [NSError VSLUnderlyingError:nil
                         localizedDescriptionKey:NSLocalizedString(@"Account unregistration failed", nil)
                     localizedFailureReasonError:[NSString stringWithFormat:NSLocalizedString(@"PJSIP status code: %d", nil), status]
                                     errorDomain:VSLAccountErrorDomain
                                       errorCode:VSLAccountErrorRegistrationFailed];
        }
        return NO;
    }
    VSLLogInfo(@"Account unregistered succesfully");
    return YES;
}

- (void)reregisterAccount {
    if ([[self.callManager callsForAccount:self] count] > 0) {
        self.shouldReregister = YES;
        [self unregisterAccount:nil];
    }
}

- (void)accountStateChanged {
    pjsua_acc_info accountInfo;
    pjsua_acc_get_info((pjsua_acc_id)self.accountId, &accountInfo);

    pjsip_status_code code = accountInfo.status;

    if (code == 0 || accountInfo.expires == -1) {
        self.accountState = VSLAccountStateDisconnected;
        if (self.shouldReregister) {
            [self registerAccountWithCompletion:^(BOOL success, NSError * _Nullable error) {
                if (success) {
                    VSLLogInfo(@"Account was re-registerd after a sucessfull unregister.");
                    self.shouldReregister = NO;
                    [self reinviteActiveCalls];
                } else {
                    VSLLogWarning(@"Unable to re-register account");
                    self.shouldReregister = NO;
                }
            }];
        }
        self.registrationInProgress = NO;
    } else if (PJSIP_IS_STATUS_IN_CLASS(code, 100) || PJSIP_IS_STATUS_IN_CLASS(code, 300)) {
        self.accountState = VSLAccountStateConnecting;
        self.registrationInProgress = YES;
    } else if (PJSIP_IS_STATUS_IN_CLASS(code, 200)) {
        self.accountState = VSLAccountStateConnected;
        self.registrationInProgress = NO;
        // Registration is succesfull.
        if (self.registrationCompletionBlock) {
            VSLLogVerbose(@"Account registered succesfully");
            self.registrationCompletionBlock(YES, nil);
            self.registrationCompletionBlock = nil;
        }
    } else {
        self.accountState = VSLAccountStateDisconnected;
    }
}

#pragma mark - Calling methods

- (void)callNumber:(NSString *)number completion:(void(^)(VSLCall *call, NSError *error))completion {
    [self.callManager startCallToNumber:number forAccount:self completion:completion];
}

- (void)addCall:(VSLCall *)call {
    [self.callManager addCall:call];
}

- (VSLCall *)lookupCall:(NSInteger)callId {
    return [self.callManager callWithCallId:callId];
}

- (VSLCall *)lookupCallWithUUID:(NSUUID *)uuid {
    return [self.callManager callWithUUID:uuid];
}

- (void)removeCall:(VSLCall *)call {
    [self.callManager removeCall:call];

    // All calls are ended, we will unregister the account.
    if ([[self.callManager callsForAccount:self] count] == 0) {
        [self unregisterAccount:nil];
    }
}

- (void)removeAllCalls {
    [self.callManager endAllCallsForAccount:self];
}

- (VSLCall *)firstCall {
    return [self.callManager firstCallForAccount:self];
}

- (VSLCall *)firstActiveCall {
    return [self.callManager firstActiveCallForAccount:self];
}

- (void)reinviteActiveCalls {
    [self.callManager reinviteActiveCallsForAccount:self];
}

@end
