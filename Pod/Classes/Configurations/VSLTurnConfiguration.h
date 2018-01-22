//
//  VSLTurnConfiguration.h
//  VialerSIPLib
//
//  Created by Maciek Gierszewski on 25/10/2017.
//

#import <Foundation/Foundation.h>
#include <VialerPJSIP/pjsua.h>

typedef NS_ENUM(NSUInteger, VSLStunPasswordType) {
    VSLStunPasswordTypePlain = PJ_STUN_PASSWD_PLAIN,
    VSLStunPasswordTypeHashed = PJ_STUN_PASSWD_HASHED,
};

@interface VSLTurnConfiguration : NSObject
@property (nonatomic, assign) BOOL enableTurn;
@property (nonatomic, assign) VSLStunPasswordType passwordType;

@property (nonatomic, strong) NSString * _Nullable server;
@property (nonatomic, strong) NSString * _Nullable username;
@property (nonatomic, strong) NSString * _Nullable password;
@end
