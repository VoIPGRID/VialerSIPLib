//
//  DDLogWrapper.m
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import "DDLogWrapper.h"

#import <CocoaLumberjack/CocoaLumberjack.h>

// Definition of the current log level
#ifdef DEBUG
static const int ddLogLevel = DDLogLevelDebug;
#else
static const int ddLogLevel = DDLogLevelWarning;
#endif

@implementation DDLogWrapper

+ (void)setup {
    //Add the Terminal and TTY(XCode console) loggers to CocoaLumberjack (simulate the default NSLog behaviour)
    DDASLLogger *aslLogger = [DDASLLogger sharedInstance];
    [DDLog addLogger:aslLogger];

    DDTTYLogger *ttyLogger = [DDTTYLogger sharedInstance];
    ttyLogger.colorsEnabled = YES;

    //Give INFO a color
    UIColor *pink = [UIColor colorWithRed:(255/255.0) green:(58/255.0) blue:(159/255.0) alpha:1.0];
    [ttyLogger setForegroundColor:[UIColor lightGrayColor] backgroundColor:nil forFlag:DDLogFlagVerbose];
    [ttyLogger setForegroundColor:[UIColor darkGrayColor] backgroundColor:nil forFlag:DDLogFlagDebug];
    [ttyLogger setForegroundColor:pink backgroundColor:nil forFlag:DDLogFlagInfo];
    [DDLog addLogger:ttyLogger];
}

+ (void)logVerbose:(NSString *)message {
    DDLogVerbose(@"%@", message);
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
