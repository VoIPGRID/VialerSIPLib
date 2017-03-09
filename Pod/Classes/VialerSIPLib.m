//
//  VialerSIPLib.m
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import "VialerSIPLib.h"

#import "Constants.h"
#import "NSError+VSLError.h"
#import "VSLAccount.h"
#import "VSLEndpoint.h"
#import "VSLLogging.h"

static NSString * const VialerSIPLibErrorDomain = @"VialerSIPLib.error";
NSString * const VSLNotificationUserInfoCallKey = @"VSLNotificationUserInfoCallKey";
NSString * const VSLNotificationUserInfoCallIdKey = @"VSLNotificationUserInfoCallIdKey";
NSString * const VSLNotificationUserInfoWindowIdKey = @"VSLNotificationUserInfoWindowIdKey";
NSString * const VSLNotificationUserInfoWindowSizeKey = @"VSLNotificationUserInfoWindowSizeKey";

@interface VialerSIPLib()
@property (strong, nonatomic) VSLEndpoint *endpoint;
@property (strong, nonatomic) VSLCallManager *callManager;
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

+ (BOOL)callKitAvailable {
    // Check if Callkit is available by checking the CallKit classes used
    if ([CXAction class] && [CXTransaction class] && [CXCall class]) {
        return true;
    } else {
        return false;
    }
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

- (VSLCallManager *)callManager {
    if (!_callManager) {
        _callManager = [[VSLCallManager alloc] init];
    }
    return _callManager;
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
        [self.endpoint destroyPJSUAInstance];
    }
}

- (VSLAccount *)createAccountWithSipUser:(id<SIPEnabledUser>  _Nonnull __autoreleasing)sipUser error:(NSError * _Nullable __autoreleasing *)error {
    VSLAccount *account = [self.endpoint getAccountWithSipAccount:sipUser.sipAccount];

    if (!account) {
        VSLAccountConfiguration *accountConfiguration = [[VSLAccountConfiguration alloc] init];
        accountConfiguration.sipAccount = sipUser.sipAccount;
        accountConfiguration.sipPassword = sipUser.sipPassword;
        accountConfiguration.sipDomain = sipUser.sipDomain;
        if ([sipUser respondsToSelector:@selector(sipProxy)]) {
            accountConfiguration.sipProxyServer = sipUser.sipProxy;
        }
        accountConfiguration.sipRegisterOnAdd = sipUser.sipRegisterOnAdd;
        accountConfiguration.dropCallOnRegistrationFailure = YES;
        
        if ([sipUser respondsToSelector:@selector(mediaStunType)]) {
            accountConfiguration.mediaStunType = sipUser.mediaStunType;
        }
        if ([sipUser respondsToSelector:@selector(sipStunType)]) {
            accountConfiguration.sipStunType = sipUser.sipStunType;
        }

        account = [[VSLAccount alloc] initWithCallManager:self.callManager];

        NSError *accountConfigError = nil;
        [account configureWithAccountConfiguration:accountConfiguration error:&accountConfigError];
        if (accountConfigError && error != NULL) {
            *error = accountConfigError;
            VSLLogError(@"Account configuration error: %@", accountConfigError);
            return nil;
        }
    }
    return account;
}

- (void)setIncomingCallBlock:(void (^)(VSLCall * _Nonnull))incomingCallBlock {
    [VSLEndpoint sharedEndpoint].incomingCallBlock = incomingCallBlock;
}

- (void)setLogCallBackBlock:(void (^)(DDLogMessage*))logCallBackBlock {
    [VSLEndpoint sharedEndpoint].logCallBackBlock = logCallBackBlock;
}

- (void)registerAccountWithUser:(id<SIPEnabledUser>  _Nonnull __autoreleasing)sipUser withCompletion:(void (^)(BOOL, VSLAccount * _Nullable))completion {
    NSError *accountConfigError;
    VSLAccount *account = [self createAccountWithSipUser:sipUser error:&accountConfigError];
    if (!account) {
        VSLLogError(@"The configuration of the account has failed:\n%@", accountConfigError);
        completion(NO, nil);
    }

    [account registerAccountWithCompletion:^(BOOL success, NSError * _Nullable error) {
        if (!success) {
            VSLLogError(@"The registration of the account has failed.\n%@", error);
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
