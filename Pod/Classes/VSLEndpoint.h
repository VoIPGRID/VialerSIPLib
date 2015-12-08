//
//  VSLEndpoint.h
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VSLAccount;
@class VSLEndpointConfiguration;
@class VSLTransportConfiguration;

@interface VSLEndpoint : NSObject

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
 The shared instance for the endpoint
 
 @warning The enpoint can be nil. If you want to bring the enpoint down use the resetSharedEnpoint function.
 */
+ (instancetype _Nullable)sharedEndpoint;

/**
 The function to bring the shared enpoint down.
 */
+ (void)resetSharedEndpoint;

/**
 This will configure the endpoint with pjsua.

 @param endpointConfiguration Instance of an end point configuration.
 @param completion The completion block which will be call when the function is done.
 
 @warning endpointConfiguration, completion can't be null.
 */
- (void)configureWithEndpointConfiguration:(VSLEndpointConfiguration  * _Nonnull)endpointConfiguration withCompletion:(void(^_Nonnull)(NSError * _Nullable error))completion;

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
@end
