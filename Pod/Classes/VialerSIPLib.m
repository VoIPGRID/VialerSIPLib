//
//  VialerSIPLib.m
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import "VialerSIPLib.h"

#import <CocoaLumberjack/CocoaLumberjack.h>
#import "VSLAccount.h"
#import "VSLAccountConfiguration.h"
#import "VSLCall.h"
#import "VSLEndpoint.h"
#import "VSLEndpointConfiguration.h"

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

- (BOOL)configureLibraryWithEndPointConfiguration:(VSLEndpointConfiguration * _Nonnull)endpointConfiguration error:(NSError **)error {

    // Make sure interrupts are handled by pjsip
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];

    // Start the Endpoint
    NSError *endpointConfigurationError;
    BOOL success = [self.endpoint startEndpointWithEndpointConfiguration:endpointConfiguration error:&endpointConfigurationError];
    if (endpointConfigurationError && error != NULL) {
        NSDictionary *userInfo = @{NSUnderlyingErrorKey : endpointConfigurationError,
                                   NSLocalizedDescriptionKey : NSLocalizedString(@"The endpoint configuration has failed.", nil)
                                   };
        *error =  [NSError errorWithDomain:VialerSIPLibErrorDomain
                                      code:VialerSIPLibErrorEndpointConfigurationFailed
                                  userInfo:userInfo];
    }
    return success;
}

- (VSLAccount * _Nullable)createAccountWithSipUser:(__autoreleasing id<SIPEnabledUser> _Nonnull)sipUser error:(NSError **) error {
    VSLAccountConfiguration *accountConfiguration = [[VSLAccountConfiguration alloc] init];
    accountConfiguration.sipUsername = sipUser.sipUsername;
    accountConfiguration.sipPassword = sipUser.sipPassword;
    accountConfiguration.sipDomain = sipUser.sipDomain;
    accountConfiguration.sipProxyServer = sipUser.sipProxy ? sipUser.sipProxy : @"";
    accountConfiguration.sipRegisterOnAdd = sipUser.sipRegisterOnAdd;

    VSLAccount *account = [[VSLAccount alloc] init];

    NSError *accountConfigError = nil;
    [account configureWithAccountConfiguration:accountConfiguration error:&accountConfigError];
    if (accountConfigError && error != NULL) {
        *error = accountConfigError;
        return nil;
    }
    return account;
}

- (VSLAccount *)firstAccount {
    return [self.endpoint.accounts firstObject];
}

@end
