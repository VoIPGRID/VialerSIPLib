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

NSString *const ErrorDomain = @"VialerSIPLib.error";

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

- (void)callNumber:(NSString * _Nonnull)number withSipUser:(id<SIPEnabledUser> _Nonnull)sipUser withCompletion:(void (^ _Nonnull)(VSLCall * _Nullable outboundCall, NSError * _Nullable error))completion {
    [self addSipAccount:sipUser withCompletion:^(NSError *error) {
        if (error) {
            NSDictionary *userInfo = @{NSUnderlyingErrorKey : error,
                                       NSLocalizedDescriptionKey : NSLocalizedStringFromTable(@"The account configuration has failed.", @"VialerSIPLib", @"account configuration error")
                                       };
            NSError *error =  [NSError errorWithDomain:ErrorDomain
                                                  code:VSLAccountConfigurationFailed
                                              userInfo:userInfo];
            completion(nil, error);
        } else {
            // TODO: VIALI-3061: Create outbound call here.
            completion(nil, nil);
        }
    }];
}

- (void)addSipAccount:(__autoreleasing id<SIPEnabledUser> _Nonnull)sipUser withCompletion:(void (^ _Nonnull)(NSError * _Nullable error))completion {
    VSLAccountConfiguration *accountConfiguration = [[VSLAccountConfiguration alloc] init];
    accountConfiguration.sipUsername = sipUser.sipUsername;
    accountConfiguration.sipPassword = sipUser.sipPassword;
    accountConfiguration.sipDomain = sipUser.sipDomain;
    accountConfiguration.sipProxyServer = sipUser.sipProxy ? sipUser.sipProxy : @"";
    accountConfiguration.sipRegisterOnAdd = sipUser.sipRegisterOnAdd;

    VSLAccount *account = [[VSLAccount alloc] init];

    [account configureWithAccountConfiguration:accountConfiguration withCompletion:completion];
}

- (void)configureLibraryWithEndPointConfiguration:(VSLEndpointConfiguration * _Nonnull)endpointConfiguration withCompletion:(void (^ _Nonnull)(NSError * _Nullable error))completion {
    [self.endpoint configureWithEndpointConfiguration:endpointConfiguration withCompletion:^(NSError * _Nullable error) {
        if (error) {
            NSDictionary *userInfo = @{NSUnderlyingErrorKey : error,
                                       NSLocalizedDescriptionKey : NSLocalizedStringFromTable(@"The endpoint configuration has failed.", @"VialerSIPLib", @"endpoint configuration error")
                                       };
            NSError *error =  [NSError errorWithDomain:ErrorDomain
                                                  code:VSLEndPointConfigurationFailed
                                              userInfo:userInfo];
            completion(error);
        } else {
            completion(nil);
        }
    }];
}

- (void)hangup {
    VSLAccount *account = [[VSLAccount alloc] init];
    [account removeAccount];
}

@end
