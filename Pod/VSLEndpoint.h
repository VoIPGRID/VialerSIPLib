//
//  VSLEndpoint.h
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VSLAccount;
@interface VSLEndpoint : NSObject

+ (instancetype)sharedEndpoint;
- (void)addAccount:(VSLAccount *)account;
@end
