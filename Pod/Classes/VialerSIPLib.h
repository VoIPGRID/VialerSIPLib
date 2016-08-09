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
};
#define VialerSIPLibErrorsString(VialerSIPLibErrors) [@[@"VialerSIPLibErrorEndpointConfigurationFailed", @"VialerSIPLibErrorAccountConfigurationFailed"] objectAtIndex:VialerSIPLibErrors]

/**
 *  The protocol which needs to be implemented in order to use the library.
 */
@protocol SIPEnabledUser <NSObject>
/**
 *  The sip account that should be used when authenticate on remote PBX.
 *
 *  @return NSString with the password.
 */
@property (readonly, nonatomic) NSString * _Nonnull sipAccount;
/**
 *  The password that should be used when authenticate on remote PBX.
 *
 *  @return NSString with the password.
 */
@property (readonly, nonatomic) NSString * _Nonnull sipPassword;
/**
 *  The domain where the PBX can be found.
 *
 *  @return NSString with the domain.
 */
@property (readonly, nonatomic) NSString * _Nonnull sipDomain;
@optional
/**
 *  When set to YES, the account will be registered on configuration.
 *
 *  Defaults to NO.
 *
 *  @return BOOL is registration should happen.
 */
@property (readonly, nonatomic) BOOL sipRegisterOnAdd;
/**
 *  The proxy address where to connect to.
 *
 *  If not set, the sipDomain will be used.
 *
 *  @return NSString with the proxy Address.
 */
@property (readonly, nonatomic) NSString * _Nonnull sipProxy;
@end

@interface VialerSIPLib : NSObject

/**
 *  If the endpoint is available to use.
 */
@property (readonly, nonatomic) BOOL endpointAvailable;

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
 *  @param sipUser    Instance that conforms to the SIPEnabledUser protocol.
 *  @param completion Completion block which will be executed when registration has completed or failed. 
 *                    It will return the success of the registration and an account if registration was successfull.
 */
- (void)registerAccountWithUser:(__autoreleasing id<SIPEnabledUser> _Nonnull)sipUser withCompletion:(void (^_Nullable)(BOOL success, VSLAccount * _Nullable account))completion;

/*
 *  This will return the first account that is available.
 *
 *  @return VSLAccount instance or null.
 */
- (VSLAccount * _Nullable)firstAccount;

- (NSArray * _Nullable)accounts;

/**
 *  Set the incoming call block for a incoming call.
 *
 *  @param incomingCallBlock block that will be invoked when an incoming call is setup.
 */
- (void)setIncomingCallBlock:(void(^ _Nonnull )(VSLCall * _Nonnull call))incomingCallBlock;

/**
 *  Get a VSLCall with the callId.
 *
 *  @param callId   NSString the callId that needs to be found.
 *  @param sipUser  Instance that conforms to SIPEnabledUser protocol.
 *
 *  @return VSCall instance of VSLCall of nil when not found.
 */
- (VSLCall * _Nullable)getVSLCallWithId:(NSString * _Nonnull)callId andSipUser:(__autoreleasing id<SIPEnabledUser> _Nonnull)sipUser;

/**
 *  Remove the configured endpoint from PJSUA.
 */
- (void)removeEndpoint;

/**
 *  This will check if there is another call in progress.
 *
 *  @param call VSLCall instance that you want to compare to.
 *
 *  @return BOOL YES if there is a call in progress.
 */
- (BOOL)anotherCallInProgress:(VSLCall * _Nonnull)call;

/**
 *  Call this method to limit the codecs to only iLBC.
 *
 *  @param activate BOOL, if YES, only iLBC will be used.
 */
- (void)onlyUseIlbc:(BOOL)activate;

@end
