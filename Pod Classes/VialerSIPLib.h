//
//  VialerSIPLib.h
//  Copyright © 2015 voipgrid.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SIPEnabledUser <NSObject>
- (NSString *)sipAccount;
- (NSString *)sipPassword;
@end

@class VSLCall;

@interface VialerSIPLib : NSObject
@property (weak, nonatomic)id <SIPEnabledUser> sipUser;

- (VSLCall *)callNumber:(NSString *)number;

@end
