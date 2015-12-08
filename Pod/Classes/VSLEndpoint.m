//
//  VSLEndpoint.m
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import "VSLEndpoint.h"

#import <CocoaLumberjack/CocoaLumberjack.h>
#import "NSString+PJString.h"
#import <VialerPJSIP/pjsua.h>
#import "VSLEndpointConfiguration.h"
#import "VSLTransportConfiguration.h"

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
static VSLEndpoint *sharedEndpoint = nil;

@interface VSLEndpoint()
@property (nonatomic, strong) VSLEndpointConfiguration *endpointConfiguration;
@property (nonatomic, strong) NSArray *accounts;
@end

@implementation VSLEndpoint

+ (id)sharedEndpoint {
    if (!sharedEndpoint) {
        sharedEndpoint = [[self alloc] init];
    }
    return sharedEndpoint;
}

+ (void)resetSharedEndpoint {
    [sharedEndpoint destoryPJSUAInstance];
    sharedEndpoint = nil;
}

- (NSArray *)accounts {
    if (!_accounts) {
        _accounts = [NSArray array];
    }
    return _accounts;
}

static void logCallBack(int level, const char *data, int len) {
    NSString *logString = [[NSString alloc] initWithUTF8String:data];

    //Strip time stamp from the front
    //TODO: check that the logmessage actually has a timestamp before removing.
    logString = [logString substringFromIndex:13];

    //The data obtained from the callback has a NewLine character at the end, remove it.
    unichar last = [logString characterAtIndex:[logString length] - 1];
    if ([[NSCharacterSet newlineCharacterSet] characterIsMember:last]) {
        logString = [logString substringToIndex:[logString length]-1];
    }

    DDLogVerbose(@"Level:%i %@", level, logString);
}

- (void)configureWithEndpointConfiguration:(VSLEndpointConfiguration  * _Nonnull)endpointConfiguration withCompletion:(void(^_Nonnull)(NSError * _Nullable error))completion {

    if (pjsua_get_state() == PJSUA_STATE_RUNNING) {
        [self destoryPJSUAInstance];
    }

    DDLogInfo(@"Creating new PJSUA instance.");
    pj_status_t status;
    status = pjsua_create();

    if (status != PJ_SUCCESS) {
        [self destoryPJSUAInstance];
        NSError *error = [NSError errorWithDomain:@"Error creating PJSUA" code:status userInfo:nil];
        completion(error);
        return;
    }

    // Configure the different logging information for the endpoint.
    pjsua_logging_config log_cfg;
    pjsua_logging_config_default(&log_cfg);
    log_cfg.cb = &logCallBack;
    log_cfg.level = (unsigned int)endpointConfiguration.logLevel;
    log_cfg.console_level = (unsigned int)endpointConfiguration.logConsoleLevel;
    log_cfg.log_filename = endpointConfiguration.logFilename.pjString;
    log_cfg.log_file_flags = (unsigned int)endpointConfiguration.logFileFlags;

    // Configure the call information for the endpoint.
    pjsua_config pj_cfg;
    pjsua_config_default(&pj_cfg);
    //    pj_cfg.cb.on_incoming_call = &SWOnIncomingCall;
    //    pj_cfg.cb.on_call_media_state = &SWOnCallMediaState;
    //    pj_cfg.cb.on_call_state = &SWOnCallState;
    //    pj_cfg.cb.on_call_transfer_status = &SWOnCallTransferStatus;
    //    pj_cfg.cb.on_call_replaced = &SWOnCallReplaced;
    //    pj_cfg.cb.on_reg_state = &SWOnRegState;
    //    pj_cfg.cb.on_nat_detect = &SWOnNatDetect;
    pj_cfg.max_calls = (unsigned int)endpointConfiguration.maxCalls;

    // Configure the media information for the endpoint.
    pjsua_media_config media_cfg;
    pjsua_media_config_default(&media_cfg);
    media_cfg.clock_rate = (unsigned int)endpointConfiguration.clockRate == 0 ? PJSUA_DEFAULT_CLOCK_RATE : (unsigned int)endpointConfiguration.clockRate;
    media_cfg.snd_clock_rate = (unsigned int)endpointConfiguration.sndClockRate;

    status = pjsua_init(&pj_cfg, &log_cfg, &media_cfg);
    if (status != PJ_SUCCESS) {
        [self destoryPJSUAInstance];
        NSError *error = [NSError errorWithDomain:@"Error initializing pjsua" code:status userInfo:nil];
        completion(error);
        return;
    }

    // Add the transport configuration to the endpoint.
    for (VSLTransportConfiguration *transportConfiguration in endpointConfiguration.transportConfigurations) {
        pjsua_transport_config transportConfig;
        pjsua_transport_config_default(&transportConfig);

        pjsip_transport_type_e transportType = (pjsip_transport_type_e)transportConfiguration.transportType;
        pjsua_transport_id transportId;

        status = pjsua_transport_create(transportType, &transportConfig, &transportId);
        if (status != PJ_SUCCESS) {
            NSError *error = [NSError errorWithDomain:@"Error creating pjsua transport" code:status userInfo:nil];
            completion(error);
            return;
        }
    }

    status = pjsua_start();
    if (status == PJ_SUCCESS) {
        DDLogInfo(@"PJSUA started succesfully");
        self.endpointConfiguration = endpointConfiguration;
        completion(nil);
    } else {
        [self destoryPJSUAInstance];
        NSError *error = [NSError errorWithDomain:@"Error starting pjsua" code:status userInfo:nil];
        completion(error);
    }
}

- (void)destoryPJSUAInstance {
    DDLogInfo(@"PJSUA was already running destroying old instance.");
    pjsua_destroy();
}

- (void)addAccount:(VSLAccount *)account {
    self.accounts = [self.accounts arrayByAddingObject:account];
}

- (void)removeAccount:(VSLAccount *)account {
    NSMutableArray *mutableArray = [self.accounts mutableCopy];
    [mutableArray removeObject:account];
    self.accounts = [mutableArray copy];
}

@end
