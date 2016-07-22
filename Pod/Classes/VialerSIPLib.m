//
//  VialerSIPLib.m
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import "VialerSIPLib.h"

#import "Constants.h"
#import <CocoaLumberJack/CocoaLumberjack.h>
#import "NSError+VSLError.h"
#import "VSLAccount.h"
#import "VSLAccountConfiguration.h"
#import "VSLEndpoint.h"

static NSString * const VialerSIPLibErrorDomain = @"VialerSIPLib.error";

@interface VialerSIPLib()
@property (strong, nonatomic) VSLEndpoint *endpoint;
@end

@implementation VialerSIPLib

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;

    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (VSLEndpoint *)endpoint {
    if (!_endpoint) {
        _endpoint = [VSLEndpoint sharedEndpoint];
    }
    return _endpoint;
}

- (BOOL)endpointAvailable {
    if (self.endpoint.state == VSLEndpointStarted) {
        return YES;
    }
    return NO;
}

- (BOOL)configureLibraryWithEndPointConfiguration:(VSLEndpointConfiguration * _Nonnull)endpointConfiguration error:(NSError * _Nullable __autoreleasing *)error {
    // Make sure interrupts are handled by pjsip
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];

    // Start the Endpoint
    NSError *endpointConfigurationError;
    BOOL success = [self.endpoint startEndpointWithEndpointConfiguration:endpointConfiguration error:&endpointConfigurationError];
    if (endpointConfigurationError && error != NULL) {
        *error = [NSError VSLUnderlyingError:endpointConfigurationError
           localizedDescriptionKey:NSLocalizedString(@"The endpoint configuration has failed.", nil)
       localizedFailureReasonError:nil
                       errorDomain:VialerSIPLibErrorDomain
                         errorCode:VialerSIPLibErrorEndpointConfigurationFailed];
    }
    return success;
}

- (void)removeEndpoint {
    if (self.endpointAvailable) {
        [self.endpoint destoryPJSUAInstance];
    }
}

- (VSLAccount *)createAccountWithSipUser:(id<SIPEnabledUser>  _Nonnull __autoreleasing)sipUser error:(NSError * _Nullable __autoreleasing *)error {
    VSLAccount *account = [self.endpoint getAccountWithSipAccount:sipUser.sipAccount];

    if (!account) {
        VSLAccountConfiguration *accountConfiguration = [[VSLAccountConfiguration alloc] init];
        accountConfiguration.sipAccount = sipUser.sipAccount;
        accountConfiguration.sipPassword = sipUser.sipPassword;
        accountConfiguration.sipDomain = sipUser.sipDomain;
        accountConfiguration.sipProxyServer = sipUser.sipProxy ? sipUser.sipProxy : @"";
        accountConfiguration.sipRegisterOnAdd = sipUser.sipRegisterOnAdd;
        accountConfiguration.dropCallOnRegistrationFailure = YES;

        account = [[VSLAccount alloc] init];

        NSError *accountConfigError = nil;
        [account configureWithAccountConfiguration:accountConfiguration error:&accountConfigError];
        if (accountConfigError && error != NULL) {
            *error = accountConfigError;
            DDLogError(@"Account configuration error: %@", accountConfigError);
            return nil;
        }
    }
    return account;
}

- (void)setIncomingCallBlock:(void (^)(VSLCall * _Nonnull))incomingCallBlock {
    [VSLEndpoint sharedEndpoint].incomingCallBlock = incomingCallBlock;
}

- (void)registerAccountWithUser:(id<SIPEnabledUser>  _Nonnull __autoreleasing)sipUser withCompletion:(void (^)(BOOL, VSLAccount * _Nullable))completion {
    NSError *accountConfigError;
    VSLAccount *account = [self createAccountWithSipUser:sipUser error:&accountConfigError];
    if (!account) {
        DDLogError(@"The configuration of the account has failed:\n%@", accountConfigError);
        completion(NO, nil);
    }

    [account registerAccountWithCompletion:^(BOOL success, NSError * _Nullable error) {
        if (!success) {
            DDLogError(@"The registration of the account has failed.\n%@", error);
            completion(NO, nil);
        } else {
            completion(YES, account);
        }
    }];
}

- (VSLCall *)getVSLCallWithId:(NSString *)callId andSipUser:(id<SIPEnabledUser>  _Nonnull __autoreleasing)sipUser {
    if (!callId) {
        return nil;
    }

    VSLAccount *account = [self.endpoint getAccountWithSipAccount:sipUser.sipAccount];

    if (!account) {
        return nil;
    }

    VSLCall *call = [account lookupCall:[callId intValue]];

    return call;
}

- (VSLAccount *)firstAccount {
    return [self.endpoint.accounts firstObject];
}

- (NSArray *)accounts {
    return self.endpoint.accounts;
}

- (BOOL)anotherCallInProgress:(VSLCall *)call {
    VSLAccount *account = [self firstAccount];
    VSLCall *activeCall = [account firstActiveCall];

    if (call.callId != activeCall.callId) {
        return YES;
    }
    return NO;
}

- (void)onlyUseIlbc:(BOOL)activate {
    [self.endpoint onlyUseILBC:activate];
}

@end
