//
//  VialerSIPLib.h
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VSLCall.h"
#import "VSLEndpointConfiguration.h"
#import "VSLTransportConfiguration.h"

/**
 *  Possible errors the VialerSIPLib can return.
 */
typedef NS_ENUM(NSUInteger, VialerSIPLibErrors) {
    /**
     *  Unable to configure the endpoint.
     */
    VialerSIPLibErrorEndpointConfigurationFailed,
    /**
     *  Unable to configure the account.
     */
    VialerSIPLibErrorAccountConfigurationFailed,
    /**
     *  Unable to register the account.
     */
    VialerSIPLibErrorAccountRegistrationFailed,
};

/**
 *  The protocol which needs to be implemented in order to use the library.
 */
@protocol SIPEnabledUser <NSObject>
/**
 *  The sip account that should be used when authenticate on remote PBX.
 *
 *  @return NSString with the password.
 */
- (NSString * _Nonnull)sipAccount;
/**
 *  The password that should be used when authenticate on remote PBX.
 *
 *  @return NSString with the password.
 */
- (NSString * _Nonnull)sipPassword;
/**
 *  The domain where the PBX can be found.
 *
 *  @return NSString with the domain.
 */
- (NSString * _Nonnull)sipDomain;
@optional
/**
 *  When set to YES, the account will be registered on configuration.
 *
 *  Defaults to NO.
 *
 *  @return BOOL is registration should happen.
 */
- (BOOL)sipRegisterOnAdd;
/**
 *  The proxy address where to connect to.
 *
 *  If not set, the sipDomain will be used.
 *
 *  @return NSString with the proxy Address.
 */
- (NSString * _Nonnull)sipProxy;
@end

@interface VialerSIPLib : NSObject

/**
 * The shared instance for the sip library.
 */
+ (instancetype _Nonnull)sharedInstance;

/**
 *  This will configure the basic Endpoint to use with pjsip.
 *
 *  @param endpointConfiguration Instance of an endpoint configuration.
 *  @param error                 Pointer to NSError pointer. Will be set to a NSError instance if it can't configure the library.
 *
 *  @return success of configuration.
 */
- (BOOL)configureLibraryWithEndPointConfiguration:(VSLEndpointConfiguration * _Nonnull)endpointConfiguration error:(NSError * _Nullable * _Nullable)error;

/**
 *  This will create and add a VSLAccount to the Endpoint.
 *
 *  @param sipUser Instance that conforms to SIPEnabledUser protocol.
 *  @param error   Pointer to NSError pointer. Will be set to a NSError instance if it can't create a VSLAccount.
 *
 *  @return VSLAccount the account that was added. It can be null.
 */
- (VSLAccount * _Nullable)createAccountWithSipUser:(__autoreleasing id<SIPEnabledUser> _Nonnull)sipUser error:(NSError * _Nullable * _Nullable)error;

/**
 *  Register the account to the incoming sip proxy for incoming calls.
 *
 *  @param sipUser Instance that conforms to the SIPEnabledUser protocol.
 *  @param error   Pointer to NSError pointer. Will be set to a NSError instance if it can't register the user.
 *
 *  @return success of registration.
 */
- (BOOL)registerAccount:(__autoreleasing id<SIPEnabledUser> _Nonnull)sipUser error:(NSError * _Nullable * _Nullable)error;

/*
 *  This will return the first account that is available.
 *
 *  @return VSLAccount instance or null.
 */
- (VSLAccount * _Nullable)firstAccount;

/**
 *  Set the incoming call block for a incoming call.
 *
 *  @param incomingCallBlock block that will be invoked when an incoming call is setup.
 */
- (void)setIncomingCallBlock:(void(^ _Nonnull )(VSLCall * _Nonnull call))incomingCallBlock;

/**
 *  Remove the configured endpoint from PJSUA.
 */
- (void)removeEndpoint;
@end
