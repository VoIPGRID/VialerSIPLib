//
//  VialerSIPLib.h
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 The error enum for this file.
 */
typedef NS_ENUM (NSUInteger, VialerSIPLibErrors) {
    VSLEndPointConfigurationFailed = 1 ,
    VSLAccountConfigurationFailed,
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

@class VSLCall;
@class VSLEndpointConfiguration;
@class VSLTransportConfiguration;

@interface VialerSIPLib : NSObject
/**
 * The shared instance for the sip library.
 */
+ (instancetype _Nonnull)sharedInstance;

/**
 This will configure the basic endpoint to use with pjsip.

 @param endpointConfiguration Instance of an endpoint configuration.
 @param completion Block which will be executed when the method finishes. It may include a NSError object.

 @warning endpointConfiguration, completion can't be null.
 */
- (void)configureLibraryWithEndPointConfiguration:(VSLEndpointConfiguration * _Nonnull)endpointConfiguration withCompletion:(void(^_Nonnull)(NSError * _Nullable error))completion;

/**
 The number that the sip library will call.
 
 @param number The phonenumber which will be called.
 @param sipUser The user information for who an account will be setup. This is bases upon a protocol.
 @param completion Completion block which will be executed when evertything has been setup. May contain a outbound call or an error object.
 
 @warning number, sipUser and completion can't be null.
 */
- (void)callNumber:(NSString * _Nonnull)number withSipUser:(id<SIPEnabledUser> _Nonnull)sipUser withCompletion:(void(^_Nonnull)(VSLCall * _Nullable outboundCall, NSError * _Nullable error))completion;

/**
 * Test function for hangup a call.
 */
- (void)hangup;
@end
