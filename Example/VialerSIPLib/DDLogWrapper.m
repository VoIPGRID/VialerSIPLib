//
//  DDLogWrapper.m
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import "DDLogWrapper.h"

@import UIKit;
#import "SPLumberjackLogFormatter.h"
#import "VialerSIPLib.h"

@implementation DDLogWrapper

+ (void)setup {
    SPLumberjackLogFormatter *logFormatter = [[SPLumberjackLogFormatter alloc] init];

    DDTTYLogger *ttyLogger = [DDTTYLogger sharedInstance];
    [ttyLogger setLogFormatter:logFormatter];

    [DDLog addLogger:ttyLogger];

    [VialerSIPLib sharedInstance].logCallBackBlock = ^(DDLogMessage *_Nonnull message) {
        [DDLogWrapper logWithDDLogMessage:message];
    };
}

+ (void)logWithDDLogMessage:(DDLogMessage *)message {
    [[DDLog sharedInstance] log:LOG_ASYNC_ENABLED message:message];
}

+ (void)logVerbose:(NSString *)message {
    DDLogVerbose(@"%@", message);
}

+ (void)logDebug:(NSString *)message {
    DDLogDebug(@"%@", message);
}

+ (void)logInfo:(NSString *)message {
    DDLogInfo(@"%@", message);
}

+ (void)logWarn:(NSString *)message {
    DDLogWarn(@"%@", message);
}

+ (void)logError:(NSString *)message {
    DDLogError(@"%@", message);
}


@end
