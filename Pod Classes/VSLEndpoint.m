//
//  VSLEndpoint.m
//  Copyright © 2015 voipgrid.com. All rights reserved.
//

#import "VSLEndpoint.h"

#import <CocoaLumberjack/CocoaLumberjack.h>
#import "pjsua.h"

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
@implementation VSLEndpoint

+ (id)sharedEndpoint {
    static dispatch_once_t onceToken;
    static VSLEndpoint *_sharedEndpoint = nil;

    dispatch_once(&onceToken, ^{
        _sharedEndpoint = [[self alloc] init];
        [_sharedEndpoint configureWithCompletion:^(NSError *error) {
            if (error) {
                DDLogError(@"Error configuring endpoint: %@", error);
            }
        }];
    });
    return _sharedEndpoint;
}

- (void)configureWithCompletion:(void (^)(NSError *error))completion {
    pj_status_t status;
    status = pjsua_create();

    if (status != PJ_SUCCESS) {
        NSError *error = [NSError errorWithDomain:@"Error creating PJSUA" code:status userInfo:nil];
        if (completion) {
            completion(error);
        }
        return;
    }

    pjsua_logging_config log_cfg;
    pjsua_logging_config_default(&log_cfg);
    log_cfg.cb = &logCallBack;
    log_cfg.level = 5; //Default
    log_cfg.console_level = 4; //Default
    //    log_cfg.log_filename = [self.endpointConfiguration.logFilename pjString];
    //    log_cfg.log_file_flags = (unsigned int)self.endpointConfiguration.logFileFlags;

    pjsua_config pj_cfg;
    pjsua_config_default(&pj_cfg);
    //    pj_cfg.cb.on_incoming_call = &SWOnIncomingCall;
    //    pj_cfg.cb.on_call_media_state = &SWOnCallMediaState;
    //    pj_cfg.cb.on_call_state = &SWOnCallState;
    //    pj_cfg.cb.on_call_transfer_status = &SWOnCallTransferStatus;
    //    pj_cfg.cb.on_call_replaced = &SWOnCallReplaced;
    //    pj_cfg.cb.on_reg_state = &SWOnRegState;
    //    pj_cfg.cb.on_nat_detect = &SWOnNatDetect;
    //    pj_cfg.max_calls = 4; //4 is also default

    pjsua_media_config media_cfg;
    pjsua_media_config_default(&media_cfg);
    //    media_cfg.clock_rate = (unsigned int)self.endpointConfiguration.clockRate;
    //    media_cfg.snd_clock_rate = (unsigned int)self.endpointConfiguration.sndClockRate;

    status = pjsua_init(&pj_cfg, &log_cfg, &media_cfg);
    if (status != PJ_SUCCESS) {
        NSError *error = [NSError errorWithDomain:@"Error initializing pjsua" code:status userInfo:nil];
        if (completion) {
            completion(error);
        }
        return;
    }

    pjsua_transport_config transportConfig;
    pjsua_transport_config_default(&transportConfig);

    pjsua_transport_id transportId;
    pjsip_transport_type_e transportType = PJSIP_TRANSPORT_TCP;

    status = pjsua_transport_create(transportType, &transportConfig, &transportId);
    if (status != PJ_SUCCESS) {
        NSError *error = [NSError errorWithDomain:@"Error creating pjsua transport" code:status userInfo:nil];
        if (completion) {
            completion(error);
        }
        return;
    }

    status = pjsua_start();
    if (status != PJ_SUCCESS) {
        NSError *error = [NSError errorWithDomain:@"Error starting pjsua" code:status userInfo:nil];
        if (completion) {
            completion(error);
        }
        return;
    }

    if (completion) {
        DDLogInfo(@"PJSUA started succesfully");
        completion(nil);
    }
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

- (void)addAccount:(VSLAccount *)account {
    DDLogWarn(@"TO BE IMPLEMENTED");
}

@end
