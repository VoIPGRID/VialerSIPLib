//
//  VSLLogging.m
//  Copyright © 2017 Devhouse Spindle. All rights reserved.
//

#import "Constants.h"
#import "VSLLogging.h"
#import "VSLEndpoint.h"

@implementation VSLLogging

+ (void)logWithFlag:(DDLogFlag)flag file:(const char *)file function:(const char *)function line:(NSUInteger)line format:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    NSString *logFile = [NSString stringWithFormat:@"%s", file];
    NSString *logFunction = [NSString stringWithFormat:@"%s", function];
    
    DDLogMessage *logMessage = [[DDLogMessage alloc] initWithMessage:message
                                                               level:ddLogLevel
                                                                flag:flag
                                                             context:0
                                                                file:logFile
                                                            function:logFunction
                                                                line:line
                                                                 tag:nil
                                                             options:(DDLogMessageOptions)0
                                                           timestamp:nil];

    if ([VSLEndpoint sharedEndpoint].logCallBackBlock) {
        [VSLEndpoint sharedEndpoint].logCallBackBlock(logMessage);
    } else {
        [[DDLog sharedInstance] log:LOG_ASYNC_ENABLED message:logMessage];
    }
    va_end(args);
}

@end
