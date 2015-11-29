//
//  HDLumberjackLogFormatter.m
//  HDLumberjackLogFormatter
//
//  Created by Harold on 25/02/14.
//  Copyright (c) 2014 hd-apps.com. All rights reserved.
//

#import "HDLumberjackLogFormatter.h"

@implementation HDLumberjackLogFormatter
- (id)init {
    if (self = [super init]) {
    #ifdef LOG_ASYNC_ENABLED
        if (LOG_ASYNC_ENABLED)
            NSLog(@"Logging is done ASYNCHRONOUSLY\n");
        else
            NSLog(@"ALL LOGGING IS DONE SYNCHRONOUSLY\n");
    #else
        NSLog(@"LOG_ASYNC_ENABLED not defined, Logging is done ASYNCHRONOUSLY\n");
    #endif
    }
    return self;
}

//Lazy initialization
- (NSDateFormatter *)timestampFormatter {
    // NSDateFormatter is NOT thread-safe but this should be a thread safe sollution
    // AS LONG AS the dateFormat is NEVER changed!

    static NSDateFormatter *_timestampFormatter = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _timestampFormatter = [[NSDateFormatter alloc] init];
#if DEBUG
        [_timestampFormatter setDateFormat:@"HH:mm:ss.SSS"];
#else
        [_timestampFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss.SSS"];
#endif    
    });
    return _timestampFormatter;
}

-(NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    NSString *logLevel;
    
    //Predefined log levels from high priority to low
    //Error Warn Info Debug Verbose
    
    switch (logMessage->_flag) {
        case DDLogFlagError     : logLevel = @"ERROR  "; break;
        case DDLogFlagWarning   : logLevel = @"WARNING"; break;
        case DDLogFlagInfo      : logLevel = @"INFO   "; break;
        case DDLogFlagDebug     : logLevel = @"DEBUG  "; break;
        case DDLogFlagVerbose   : logLevel = @"VERBOSE"; break;
        default                 : logLevel = @"un-def "; break;
    }
    //e.g. 10:40:36.453 in DEBUG
    //otherwise 2014/07/30 10:45:41.823
    //Strip time zone
    NSString *timestamp = [[self timestampFormatter] stringFromDate:logMessage->_timestamp];
    
    //Has:  /Users/Harold/Programming/CrewLink 2/CrewLinkCore/CrewLinkCore/AppDelegate.m
    //Want: RootViewController_iPhone
    NSString *fileName = [NSString stringWithFormat:@"%@",  logMessage->_file];
    NSRange lastSlash = [fileName rangeOfString:@"/" options:NSBackwardsSearch];
    //Create string from last Slash till end
    fileName = [fileName substringFromIndex:lastSlash.location+1];
    //Strip last 2 characters form string (.h/.m)
    fileName = [fileName substringToIndex:fileName.length-2];
    
    NSString *function = [NSString stringWithFormat:@"%@",  logMessage->_function];
    //Ad a : to function name if it does not have one. Nicer with line number
    if (![function hasSuffix:@":"])
        function = [NSString stringWithFormat:@"%@:",function];
    
    //ERROR   2014/07/30 11:08:26.363 [AppDelegate application:didFinishLaunchingWithOptions:29] This is an ERROR
    //With DEBUG defined
    //ERROR   11:09:20.363 [AppDelegate application:didFinishLaunchingWithOptions:29] This is an ERROR
    return [NSString stringWithFormat:@"%@ %@ [%@ %@%tu] %@", logLevel, timestamp, fileName, function, logMessage->_line ,logMessage->_message];
}

@end
