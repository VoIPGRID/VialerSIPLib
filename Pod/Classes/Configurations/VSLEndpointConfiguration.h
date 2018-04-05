//
//  VSLEndPointConfiguration.h
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VSLIpChangeConfiguration.h"
#import "VSLStunConfiguration.h"
#import "VSLCodecConfiguration.h"


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
@property (strong, nonatomic) NSString * _Nullable logFilename;

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
@property (strong, nonatomic) NSArray * _Nonnull transportConfigurations;

/**
 * Coniguration property to not offer the video codec in the INVITE.
 *
 * Default: NO
 */
@property (nonatomic) BOOL disableVideoSupport;

/**
 * The available STUN configuration
 */
@property (nonatomic) VSLStunConfiguration * _Nullable stunConfiguration;

/**
 * The IP change configuration, what happens when an ip address changes.
 */
@property (nonatomic) VSLIpChangeConfiguration * _Nullable ipChangeConfiguration;

/**
 * The codecs that are going to be used by the endpoint
 */
@property (nonatomic) VSLCodecConfiguration * _Nullable codecConfiguration;

/**
 * Whether the account needs to be unregistered after a call has been made
 *
 * Default: No
 *
 * @return BOOL
 */
@property (nonatomic) BOOL unregisterAfterCall;

/**
 *  To check if the endpoint has a tcp configuration.
 *
 *  @return BOOL
 */
-(BOOL)hasTCPConfiguration;

/**
 * To check if the endpoint has a tls configuration.
 *
 * @return BOOL
 */
-(BOOL)hasTLSConfiguration;

/**
 * To check if the endpoint has an udp configuration.
 *
 * @return BOOL
 */
-(BOOL)hasUDPConfiguration;

/**
 * Optional user agent string (default empty). If it's empty, no
 * User-Agent header will be sent with outgoing requests.
 */
@property (strong, nonatomic) NSString * _Nullable userAgent;

@end
