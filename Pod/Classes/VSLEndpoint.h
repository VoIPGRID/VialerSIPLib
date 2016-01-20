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

typedef NS_ENUM(NSInteger, VSLEndpointError) {
    VSLEndpointErrorCannotCreatePJSUA,
    VSLEndpointErrorCannotInitPJSUA,
    VSLEndpointErrorCannotAddTransportConfiguration,
    VSLEndpointErrorCannotStartPJSUA,
    VSLEndpointErrorCannotCreateThread
};

typedef NS_ENUM(NSInteger, VSLEndpointState) {
    VSLEndpointStopped,
    VSLEndpointStarting,
    VSLEndpointStarted
};

@interface VSLEndpoint : NSObject

@property (nonatomic) VSLEndpointState state;
@property (readonly) pj_pool_t * _Nullable pjPool;
@property (copy, nonatomic) void (^ _Nonnull incomingCallBlock)(VSLCall * _Nullable call);

/**
 References to the account that have been added to the endpoint.
 To add accounts as reference use the addAccount function.
 To remove accounts use the removeAccount function.
 
 @warning this property is readonly and can be null
 */
@property (readonly, nonatomic) NSArray * _Nullable accounts;

/**
 The endpoint configuration that has been set in the configure function for the endpoint.

 @warning endpointConfiguration is readonly and also can't be null.
 */
@property (readonly) VSLEndpointConfiguration * _Nonnull endpointConfiguration;

/**
 The shared instance for the endpoint.

 @warning The endpoint cannot be nil.
 */
+ (instancetype _Nonnull)sharedEndpoint;

/**
 This will configure the endpoint with pjsua.

 @param endpointConfiguration Instance of an end point configuration.
 @param error Pointer to NSError pointer. Will be set to a NSError instance if cannot start endpoint

 @return BOOL success of configuration.

 @warning endpointConfiguration can't be null.
 */
- (BOOL)startEndpointWithEndpointConfiguration:(VSLEndpointConfiguration  * _Nonnull)endpointConfiguration error:(NSError * _Nullable * _Nullable)error;

/**
 This will add the account as reference to the endpoint.

 @param account The account that has been added.

 @warning account can't be null.
 */
- (void)addAccount:(VSLAccount * _Nonnull)account;

/**
 This will remove the account reference in the endpoint

 @param account The account that needs to be removed.

 @warning account can't be null.
 */
- (void)removeAccount:(VSLAccount * _Nonnull)account;

/**
 Returns an account if it is available otherwise return nil.
 
 @param sipUserName NSString the sip username you want to check.
 
 @returns VSLAccount instance of the account. It can also return null
 */
- (VSLAccount * _Nullable)getAccountWithSipUsername:(NSString * _Nonnull)sipUsername;


@end
