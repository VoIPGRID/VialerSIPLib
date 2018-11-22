//
//  VSLAccount.h
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VSLAccountConfiguration.h"

@class VSLCall, VSLCallManager;

/**
 *  Possible errors the account can return.
 */
typedef NS_ENUM(NSInteger, VSLAccountErrors) {
    /**
     *  Unable to configure the account
     */
    VSLAccountErrorCannotConfigureAccount,
    /**
     *  Unable to call the number
     */
    VSLAccountErrorFailedCallingNumber,
    /**
     *  Unable to register the account
     */
    VSLAccountErrorRegistrationFailed,
    /**
     *  Unable to register the account because account is invalid.
     */
    VSLAccountErrorInvalidAccount,
    /**
     *  When the account has invalid info and registrations fails with a 403.
     */
    VSLAccountErrorRegistrationFailedInvalidAccount
};
#define VSLAccountErrorsString(VSLAccountErrors) [@[@"VSLAccountErrorCannotConfigureAccount", @"VSLAccountErrorFailedCallingNumber", @"VSLAccountErrorRegistrationFailed", @"VSLAccountErrorInvalidAccount", @"VSLAccountErrorRegistrationFailedInvalidAccount"] objectAtIndex:VSLAccountErrors]

/**
 *  Possible states for an account.
 */
typedef NS_ENUM(NSInteger, VSLAccountState) {
    /**
     *  Account isn't added to the endpoint
     */
    VSLAccountStateOffline,
    /**
     *  Account is connecting with endpoint
     */
    VSLAccountStateConnecting,
    /**
     *  Account is connected with endpoint
     */
    VSLAccountStateConnected,
    /**
     *  Account is disconnected from endpoint
     */
    VSLAccountStateDisconnected,
};
#define VSLAccountStateString(VSLAccountState) [@[@"VSLAccountStateOffline", @"VSLAccountStateConnecting", @"VSLAccountStateConnected", @"VSLAccountStateDisconnected"] objectAtIndex:VSLAccountState]

/**
 *  Completionblock that will be called after the account was registered.
 *
 *  @param success BOOL will indicate the success of the registration.
 *  @param error   NSError instance with possible error. Can be nil.
 */
typedef void (^RegistrationCompletionBlock)(BOOL success, NSError * _Nullable error);

@interface VSLAccount : NSObject

/**
 *  The accountId which an account receives when it is added.
 */
@property (nonatomic) NSInteger accountId;

/**
 *  The current state of an account.
 */
@property (readonly, nonatomic) VSLAccountState accountState;

/**
 *  The current SIP registration status code.
 */
@property (readonly, nonatomic) NSInteger registrationStatus;

/**
 *  A Boolean value indicating whether the account is registered.
 */
@property (readonly, nonatomic) BOOL isRegistered;

/**
 *  An up to date expiration interval for the account registration session.
 */
@property (readonly, nonatomic) NSInteger registrationExpiresTime;

/**
 *  The account configuration that has been set in the configure function for the account.
 */
@property (readonly, nonatomic) VSLAccountConfiguration * _Nonnull accountConfiguration;

@property (readwrite, nonatomic) BOOL forceRegistration;

/**
 * This init is not available.
 */
-(instancetype _Nonnull)init __attribute__((unavailable("init not available")));

/**
 * Designated initializer
 *
 * @param callManager A instance of VSLCallManager.
 */
-(instancetype _Nonnull)initWithCallManager:(VSLCallManager * _Nonnull)callManager;

/**
 *  This will configure the account on the endpoint.
 *
 *  @param accountConfiguration Instance of the VSLAccountConfiguration.
 *  @param error                Pointer to NSError pointer. Will be set to a NSError instance if cannot configure account.
 *
 *  @return BOOL success of configuration.
 */
- (BOOL)configureWithAccountConfiguration:(VSLAccountConfiguration * _Nonnull)accountConfiguration error:(NSError * _Nullable * _Nullable)error;

/**
 *  Register the account with pjsua.
 *
 *  @param completion RegistrationCompletionBlock, will be called with success of registration and possible error.
 */
- (void)registerAccountWithCompletion:(_Nullable RegistrationCompletionBlock)completion;

/**
 *  Unregister the account if registered.
 *
 *  If an account isn't registered, there will be no unregister message sent to the proxy, and will return success.
 *
 *  @param error Pointer to NSError pointer. Will be set to a NSError instance if cannot register the account.
 *
 *  @return BOOL success if account is no longer registered
 */
- (BOOL)unregisterAccount:(NSError * _Nullable * _Nullable)error;

/**
 *  Will unregister the account and will re-register the account once the account
 *  state reaches "unregistered".
 */
- (void)reregisterAccount;

/**
 *  This will remove the account from the Endpoint and will also de-register the account from the server.
 */
- (void)removeAccount;

/**
 *  This will set the state of the account. Based on the pjsua account state and the VSLAccountState enum.
 */
- (void)accountStateChanged;

/**
 *  The number that the sip library will call.
 *
 *  @param number     The phonenumber which will be called.
 *  @param completion Completion block which will be executed when everything has been setup. May contain a outbound call or an error object.
 */
- (void)callNumber:(NSString * _Nonnull)number completion:(void(^_Nonnull)(VSLCall * _Nullable call, NSError * _Nullable error))completion;

/**
 *  This will add the call to the account.
 *
 *  @param call The call instance that should be added.
 */
- (void)addCall:(VSLCall * _Nonnull)call __attribute__((unavailable("Deprecated, use VSLCallManager -addCall: instead")));

/**
 *  This will check if there is a call present on this account given the callId.
 *
 *  @param callId The callId of the call.
 *
 *  @return VSLCall instance.
 */
- (VSLCall * _Nullable)lookupCall:(NSInteger)callId;

/**
 *  This will remove the call from the account.
 *
 *  @param call VSLCall instance that should be removed from the account.
 */
- (void)removeCall:(VSLCall * _Nonnull)call __attribute__((unavailable("Deprecated, use VSLCallManager -removeCall: instead")));;

/**
 *  Remove all calls connected to account.
 */
- (void)removeAllCalls;

/**
 *  Get the first call available to this account.
 *
 *  @return VSLCall instance can also return nil.
 */
- (VSLCall * _Nullable)firstCall;

/**
 *  Get the first active call available to this account.
 *
 *  @return VSLCall instance can also return nil.
 */
- (VSLCall * _Nullable)firstActiveCall;

@end
