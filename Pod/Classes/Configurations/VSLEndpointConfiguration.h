//
//  VSLEndPointConfiguration.h
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VSLEndpointConfiguration : NSObject

/**
 *  Maximum calls to support.
 *
 *  The value specified here must be smaller than the compile time maximum settings PJSUA_MAX_CALLS,
 *  which by default is 32. To increase this limit, the library must be recompiled with new PJSUA_MAX_CALLS value.
 *
 *  Default value: 4
 */
@property (nonatomic) NSUInteger maxCalls;

/**
 *  Input verbosity level
 *
 *  Default value: 5
 */
@property (nonatomic) NSUInteger logLevel;

/**
 *  Verbosity level for console.
 *
 *  Default value: 4
 */
@property (nonatomic) NSUInteger logConsoleLevel;

/**
 *  Optional log filename.
 *
 *  Default value: nil
 */
@property (strong, nonatomic) NSString *logFilename;

/**
 *  Additional flags to be given to pj_file_open() when opening the log file.
 *
 *  By default, the flag is PJ_O_WRONLY.
 *  Application may set PJ_O_APPEND here so that logs are appended to existing file instead of overwriting it.
 *
 *  Default value: PJ_O_APPEND
 */
@property (nonatomic) NSUInteger logFileFlags;

/**
 *  Clock rate to be applied to the conference bridge.
 *
 *  If value is zero, default clock rate will be used (PJSUA_DEFAULT_CLOCK_RATE).
 *
 *  Default value: 1600
 */
@property (nonatomic) NSUInteger clockRate;

/**
 *  Clock rate to be applied when opening the sound device.
 *
 *  If value is zero, conference bridge clock rate will be used.
 *
 *  Default value: 0
 */
@property (nonatomic) NSUInteger sndClockRate;

/**
 *  An array which will hold all the configured transports.
 */
@property (strong, nonatomic) NSArray *transportConfigurations;

/**
 *  To check if the endpoint has a tcp configuration.
 *
 *  @return BOOL
 */
-(BOOL)hasTCPConfiguration;
@end
