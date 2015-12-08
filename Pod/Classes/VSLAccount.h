//
//  VSLAccount.h
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VSLAccountConfiguration.h"

/**
 The states which an account can have.
 */
typedef NS_ENUM(NSInteger, VSLAccountState) {
    VSLAccountStateOffline,
    VSLAccountStateDisconnected,
    VSLAccountStateConnecting,
    VSLAccountStateConnected
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
 @param completion Completion block which will be executed when the
 
 @warning accountConfiguration, completion can't be null.
 */
- (void)configureWithAccountConfiguration:(VSLAccountConfiguration *_Nonnull)accountConfiguration withCompletion:(void(^_Nonnull)(NSError * _Nullable error))completion;

/**
 This will remove the account from the endpoint and will also de-register the account from the server.
 */
- (void)removeAccount;
@end
