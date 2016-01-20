//
//  VSLEndpoint.h
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VialerPJSIP/pjsua.h>
#import "VSLEndpointConfiguration.h"

@class VSLAccount;
@class VSLCall;
@class VSLTransportConfiguration;

/**
 *  Possible errors the Endpoint can return.
 */
typedef NS_ENUM(NSInteger, VSLEndpointError) {
    /**
     *  Unable to create the pjsip library.
     */
    VSLEndpointErrorCannotCreatePJSUA,
    /**
     *  Unable to initialize the pjsip library.
     */
    VSLEndpointErrorCannotInitPJSUA,
    /**
     *  Unable to add transport configuration to endpoint.
     */
    VSLEndpointErrorCannotAddTransportConfiguration,
    /**
     *  Unable to start the pjsip library.
     */
    VSLEndpointErrorCannotStartPJSUA,
    /**
     *  Unable to create the thread for pjsip.
     */
    VSLEndpointErrorCannotCreateThread
};

/**
 *  Possible states for the Endpoint.
 */
typedef NS_ENUM(NSInteger, VSLEndpointState) {
    /**
     *  Endpoint not active.
     */
    VSLEndpointStopped,
    /**
     *  Endpoint is starting.
     */
    VSLEndpointStarting,
    /**
     *  Endpoint is running.
     */
    VSLEndpointStarted
};


@interface VSLEndpoint : NSObject

/**
 *  Current state of the endpoint.
 */
@property (nonatomic) VSLEndpointState state;

/**
 *  The pool associated with the endpoint.
 */
@property (readonly) pj_pool_t * _Nullable pjPool;

/**
 *  The incomingCallBlock will be called when an incoming call is received by pjsip.
 */
@property (copy, nonatomic) void (^ _Nonnull incomingCallBlock)(VSLCall * _Nullable call);

/**
 *  References to the account that have been added to the endpoint.
 *  To add accounts as reference use the addAccount function.
 *  To remove accounts use the removeAccount function.
 */
@property (readonly, nonatomic) NSArray * _Nullable accounts;

/**
 *  The endpoint configuration that has been set in the configure function for the endpoint.
 */
@property (readonly) VSLEndpointConfiguration * _Nonnull endpointConfiguration;

/**
 *  The shared instance for the endpoint.
 *
 *  @return The singleton instance.
 */
+ (instancetype _Nonnull)sharedEndpoint;

/**
 *  This will configure the endpoint with pjsua.
 *
 *  @param endpointConfiguration Instance of an end point configuration.
 *  @param error                 Pointer to NSError pointer. Will be set to a NSError instance if cannot start endpoint.
 *
 *  @return BOOL success of configuration.
 */
- (BOOL)startEndpointWithEndpointConfiguration:(VSLEndpointConfiguration  * _Nonnull)endpointConfiguration error:(NSError * _Nullable * _Nullable)error;

/**
 *  This will add the account as reference to the endpoint.
 *
 *  @param account The account that has been added.
 */
- (void)addAccount:(VSLAccount * _Nonnull)account;

/**
 *  This will search for the account given the accountId.
 *
 *  @param accountId ID of the account.
 *
 *  @return VSLAccount Instance if found.
 */
- (VSLAccount * _Nullable)lookupAccount:(NSInteger)accountId;

/**
 *  This will remove the account reference in the endpoint.
 *
 *  @param account The account that needs to be removed.
 */
- (void)removeAccount:(VSLAccount * _Nonnull)account;

/**
 *  Returns an account if it is available.
 *
 *  @param sipUsername NSString the sip username you want to check.
 *
 *  @return VSLAccount instance of the account.
 */
- (VSLAccount * _Nullable)getAccountWithSipUsername:(NSString * _Nonnull)sipUsername;

@end
