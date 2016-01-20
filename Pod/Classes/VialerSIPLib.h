//
//  VialerSIPLib.h
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VSLCall.h"
/**
 The error enum for this file.
 */
typedef NS_ENUM (NSUInteger, VialerSIPLibErrors) {
    VialerSIPLibErrorEndpointConfigurationFailed,
    VialerSIPLibErrorAccountConfigurationFailed,
    VialerSIPLibErrorAccountRegistrationFailed,
};

/**
 The protocol which needs to be implemented in order to use the library.
 */
@protocol SIPEnabledUser <NSObject>
- (NSString * _Nonnull)sipUsername;
- (NSString * _Nonnull)sipPassword;
- (NSString * _Nonnull)sipDomain;
@optional
- (BOOL)sipRegisterOnAdd;
- (NSString * _Nonnull)sipProxy;
@end

@class VSLEndpointConfiguration;
@class VSLTransportConfiguration;

@interface VialerSIPLib : NSObject
/**
 * The shared instance for the sip library.
 */
+ (instancetype _Nonnull)sharedInstance;

/**
 This will configure the basic Endpoint to use with pjsip.

 @param endpointConfiguration Instance of an endpoint configuration.
 @param error Pointer to NSError pointer. Will be set to a NSError instance if it can't configure the library.

 @return BOOL success of configuration.

 @warning endpointConfiguration can't be null.
 */
- (BOOL)configureLibraryWithEndPointConfiguration:(VSLEndpointConfiguration * _Nonnull)endpointConfiguration error:(NSError * _Nullable * _Nullable)error;

/**
 This will create and add a VSLAccount to the Endpoint.

 @param sipUser instance that conforms to SIPEnabledUser protocol
 @param error Pointer to NSError pointer. Will be set to a NSError instance if it can't create a VSLAccount.

 @return VSLAccount the account that was added. It can be null.

 @warning sipUser can't be null.
 */
- (VSLAccount * _Nullable)createAccountWithSipUser:(__autoreleasing id<SIPEnabledUser> _Nonnull)sipUser error:(NSError * _Nullable * _Nullable)error;

/**
 Register the account to the incoming sip proxy for incoming calls.

 @param sipUser instance that conforms to the SIPEnabledUser protocol.
 @param error Pointer to NSError pointer. Will be set to a NSError instance if it can't register the user.

 @warning sipUser can't be null.
 */
- (BOOL)registerAccount:(__autoreleasing id<SIPEnabledUser> _Nonnull)sipUser error:(NSError * _Nullable * _Nullable)error;

/**
 This will return the first account that is available.

 @return VSLAccount instance or null.
 */
- (VSLAccount * _Nullable)firstAccount;


/**
 Set the incoming call block for a incoming call.
 */
- (void)setIncomingCallBlock:(void(^ _Nonnull )(VSLCall * _Nonnull call))incomingCallBlock;

@end
