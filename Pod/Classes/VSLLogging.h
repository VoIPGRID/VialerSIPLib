//
//  VSLLogging.h
//  Copyright © 2017 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

@interface VSLLogging : NSObject

#define VSLLog(flag, fnct, frmt, ...) \
[VSLLogging logWithFlag: flag file:__FILE__ function: fnct line:__LINE__ format:(frmt), ## __VA_ARGS__]

#define VSLLogVerbose(frmt, ...)    VSLLog(DDLogFlagVerbose,    __PRETTY_FUNCTION__, frmt, ## __VA_ARGS__)
#define VSLLogDebug(frmt, ...)      VSLLog(DDLogFlagDebug,      __PRETTY_FUNCTION__, frmt, ## __VA_ARGS__)
#define VSLLogInfo(frmt, ...)       VSLLog(DDLogFlagInfo,       __PRETTY_FUNCTION__, frmt, ## __VA_ARGS__)
#define VSLLogWarning(frmt, ...)    VSLLog(DDLogFlagWarning,    __PRETTY_FUNCTION__, frmt, ## __VA_ARGS__)
#define VSLLogError(frmt, ...)      VSLLog(DDLogFlagError,      __PRETTY_FUNCTION__, frmt, ## __VA_ARGS__)

+ (void) logWithFlag:(DDLogFlag)flag
                file: (const char *_Nonnull)file
            function:(const char*_Nonnull)function
                line:(NSUInteger)line
              format:(NSString * _Nonnull)format, ... NS_FORMAT_FUNCTION(5, 6);
@end
