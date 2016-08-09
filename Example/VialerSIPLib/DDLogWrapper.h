//
//  DDLogWrapper.h
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DDLogWrapper : NSObject
+ (void)setup;
+ (void)logVerbose:(NSString *)message;
+ (void)logWarn:(NSString *)message;
+ (void)logError:(NSString *)message;
+ (void)logInfo:(NSString *)message;
@end
