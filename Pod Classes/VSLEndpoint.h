//
//  VSLEndpoint.h
//  Copyright © 2015 voipgrid.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VSLAccount;
@interface VSLEndpoint : NSObject

+ (instancetype)sharedEndpoint;
- (void)addAccount:(VSLAccount *)account;
@end
