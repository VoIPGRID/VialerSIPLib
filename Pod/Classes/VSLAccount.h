//
//  VSLAccount.h
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VSLAccountConfiguration.h"

@class VSLCall;

/**
 The ErrorCodes VSLAccount can return.
 */
typedef NS_ENUM(NSInteger, VSLAccountErrors) {
    VSLAccountErrorCannotConfigureAccount,
    VSLAccountErrorFailedCallingNumber,
    VSLAccountErrorRegistrationFailed,
    VSLAccountErrorSettingOnlineStatus,
};

/**
 The states which an account can have.
 */
typedef NS_ENUM(NSInteger, VSLAccountState) {
    VSLAccountStateOffline,
    VSLAccountStateConnecting,
    VSLAccountStateConnected,
    VSLAccountStateDisconnected,
};

@interface VSLAccount : NSObject

/**
 The accountId which an account receives when it is added.
 */
@property (nonatomic) NSInteger accountId;

/**
 The current state of an account.

 @warning this property is readonly
 */
@property (readonly, nonatomic) VSLAccountState accountState;

/**
 The account configuration that has been set in the configure function for the account.
 
 @warning accountConfiguration is readonly and also can't be null.
 */
@property (readonly, nonatomic) VSLAccountConfiguration * _Nonnull accountConfiguration;

/**
 This will configure the account on the endpoint.

 @param accountConfiguration Instance of the VSLAccountConfiguration.
 @param error Pointer to NSError pointer. Will be set to a NSError instance if cannot configure account.

 @return BOOL success of configuration.

 @warning accountConfiguration can't be null.
 */
- (BOOL)configureWithAccountConfiguration:(VSLAccountConfiguration * _Nonnull)accountConfiguration error:(NSError * _Nullable * _Nullable)error;

/**
 Register the account with pjsua.

 @param error Pointer to NSError pointer. Will be set to a NSError instance if cannot register the account.
 */
- (BOOL)registerAccount:(NSError * _Nullable * _Nullable)error;

/**
 This will remove the account from the Endpoint and will also de-register the account from the server.
 */
- (void)removeAccount;

/**
 This will set the state of the account. Based on the pjsua account state and the VSLAccountState enum.
 */
- (void)accountStateChanged;

/**
 The number that the sip library will call.

 @param number The phonenumber which will be called.
 @param completion Completion block which will be executed when evertything has been setup. May contain a outbound call or an error object.

 @warning number and completion can't be null.
 */
- (void)callNumber:(NSString * _Nonnull)number withCompletion:(void(^_Nonnull)(NSError * _Nullable error, VSLCall * _Nullable outboundCall))completion;

/**
 This will check if there is a call present on this account given the callId.

 @param callId The callId of the call.

 @return If call was found, it will return the call.
 */
- (VSLCall * _Nullable)lookupCall:(NSInteger)callId;

/**
 This will add the call to the account.

 @param call The call instance that should be added

 @warning call can't be null.
 */
- (void)addCall:(VSLCall * _Nonnull)call;

@end
