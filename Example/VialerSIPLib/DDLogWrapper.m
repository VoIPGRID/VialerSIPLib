//
//  DDLogWrapper.m
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import "DDLogWrapper.h"

@import UIKit;
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "SPLumberjackLogFormatter.h"

// Definition of the current log level
#ifdef DEBUG
static const int ddLogLevel = DDLogLevelDebug;
#else
static const int ddLogLevel = DDLogLevelWarning;
#endif

@implementation DDLogWrapper

+ (void)setup {
    SPLumberjackLogFormatter *logFormatter = [[SPLumberjackLogFormatter alloc] init];

    if ([[[UIDevice currentDevice] systemVersion] compare:@"10" options:NSNumericSearch] == NSOrderedAscending) {
        DDTTYLogger *ttyLogger = [DDTTYLogger sharedInstance];
        [ttyLogger setLogFormatter:logFormatter];
        [DDLog addLogger:ttyLogger];
    }

    //Add a logger to CocoaLumberjack, the DDASL logger simulate the default NSLog behaviour.
    DDASLLogger *aslLogger = [DDASLLogger sharedInstance];
    aslLogger.logFormatter = logFormatter;
    [DDLog addLogger:aslLogger];
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
