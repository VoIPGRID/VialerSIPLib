//
//  DDLogWrapper.h
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

@interface DDLogWrapper : NSObject
+ (void)setup;
+ (void)logWithDDLogMessage:(DDLogMessage *)message NS_SWIFT_NAME(log(message:));
+ (void)logVerbose:(NSString *)message;
+ (void)logDebug:(NSString *)message;
+ (void)logWarn:(NSString *)message;
+ (void)logError:(NSString *)message;
+ (void)logInfo:(NSString *)message;
@end
