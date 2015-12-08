//
//  VialerSIPLib.h
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SIPEnabledUser <NSObject>
- (NSString *)sipAccount;
- (NSString *)sipPassword;
@end

@class VSLCall;

@interface VialerSIPLib : NSObject
@property (strong, nonatomic)id <SIPEnabledUser> sipUser;

- (VSLCall *)callNumber:(NSString *)number;

@end
