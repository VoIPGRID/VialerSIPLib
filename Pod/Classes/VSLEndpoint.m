//
//  VSLEndpoint.m
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import "VSLEndpoint.h"

#import <CocoaLumberjack/CocoaLumberjack.h>
#import "NSError+VSLError.h"
#import "NSString+PJString.h"
#import "VSLCall.h"
#import "VSLTransportConfiguration.h"

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

static NSString * const VSLEndpointErrorDomain = @"VialerSIPLib.VSLEndpoint.error";

static void logCallBack(int level, const char *data, int len);
static void onCallState(pjsua_call_id callId, pjsip_event *event);
static void onIncomingCall(pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata);
static void onCallMediaState(pjsua_call_id call_id);
static void onCallTransferStatus(pjsua_call_id call_id, int st_code, const pj_str_t *st_text, pj_bool_t final, pj_bool_t *p_cont);
static void onCallReplaced(pjsua_call_id old_call_id, pjsua_call_id new_call_id);
static void onRegState(pjsua_acc_id acc_id);
static void onNatDetect(const pj_stun_nat_detect_result *res);

@interface VSLEndpoint()
@property (strong, nonatomic) VSLEndpointConfiguration *endpointConfiguration;
@property (strong, nonatomic) NSArray *accounts;
@property (assign) pj_pool_t *pjPool;
@end

@implementation VSLEndpoint

#pragma mark - Singleton

+ (id)sharedEndpoint {
    static VSLEndpoint *_sharedEndpoint;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedEndpoint = [[VSLEndpoint alloc] init];
    });
    return _sharedEndpoint;
}

#pragma mark - Properties

- (NSArray *)accounts {
    if (!_accounts) {
        _accounts = [NSArray array];
    }
    return _accounts;
}

#pragma mark - Lifecycle

- (BOOL)startEndpointWithEndpointConfiguration:(VSLEndpointConfiguration  * _Nonnull)endpointConfiguration error:(NSError **)error {
    // Do nothing if it's already started.
    if (self.state == VSLEndpointStarted) {
        return YES;
    } else if (self.state == VSLEndpointStarting) {
        // Do nothing if the endpoint is currently in the progress of starting.
        return NO;
    }

    DDLogInfo(@"Creating new PJSIP Endpoint instance.");
    self.state = VSLEndpointStarting;

    // Create PJSUA on the main thread to make all subsequent calls from the main
    // thread.
    pj_status_t status = pjsua_create();
    if (status != PJ_SUCCESS) {
        self.state = VSLEndpointStopped;
        if (error != NULL) {
            *error = [NSError VSLUnderlyingError:nil
               localizedDescriptionKey:NSLocalizedString(@"Could not create PJSIP Enpoint instance", nil)
           localizedFailureReasonError:[NSString stringWithFormat:NSLocalizedString(@"PJSIP status code: %d", nil), status]
                           errorDomain:VSLEndpointErrorDomain
                             errorCode:VSLEndpointErrorCannotCreatePJSUA];
        }
        return NO;
    }

    // Create Thread & Pool
    NSError *threadError;
    if (![self createPJThreadAndPoolwithError:&threadError]) {
        *error = threadError;
        return NO;
    }

    // Configure the different logging information for the endpoint.
    pjsua_logging_config logConfig;
    pjsua_logging_config_default(&logConfig);
    logConfig.cb = &logCallBack;
    logConfig.level = (unsigned int)endpointConfiguration.logLevel;
    logConfig.console_level = (unsigned int)endpointConfiguration.logConsoleLevel;
    logConfig.log_filename = endpointConfiguration.logFilename.pjString;
    logConfig.log_file_flags = (unsigned int)endpointConfiguration.logFileFlags;

    // Configure the call information for the endpoint.
    pjsua_config endpointConfig;
    pjsua_config_default(&endpointConfig);
    endpointConfig.cb.on_incoming_call = &onIncomingCall;
    endpointConfig.cb.on_call_media_state = &onCallMediaState;
    endpointConfig.cb.on_call_state = &onCallState;
    endpointConfig.cb.on_call_transfer_status = &onCallTransferStatus;
    endpointConfig.cb.on_call_replaced = &onCallReplaced;
    endpointConfig.cb.on_reg_state = &onRegState;
    endpointConfig.cb.on_nat_detect = &onNatDetect;
    endpointConfig.max_calls = (unsigned int)endpointConfiguration.maxCalls;

    // Configure the media information for the endpoint.
    pjsua_media_config mediaConfig;
    pjsua_media_config_default(&mediaConfig);
    mediaConfig.clock_rate = (unsigned int)endpointConfiguration.clockRate == 0 ? PJSUA_DEFAULT_CLOCK_RATE : (unsigned int)endpointConfiguration.clockRate;
    mediaConfig.snd_clock_rate = (unsigned int)endpointConfiguration.sndClockRate;

    // Initialize Endpoint.
    status = pjsua_init(&endpointConfig, &logConfig, &mediaConfig);
    if (status != PJ_SUCCESS) {
        [self destoryPJSUAInstance];
        if (error != NULL) {
            *error = [NSError VSLUnderlyingError:nil
               localizedDescriptionKey:NSLocalizedString(@"Could not initialize Endpoint.", nil)
           localizedFailureReasonError:[NSString stringWithFormat:NSLocalizedString(@"PJSIP status code: %d", nil), status]
                           errorDomain:VSLEndpointErrorDomain
                             errorCode:VSLEndpointErrorCannotInitPJSUA];
        }
        return NO;
    }

    // Add the transport configuration to the endpoint.
    for (VSLTransportConfiguration *transportConfiguration in endpointConfiguration.transportConfigurations) {
        pjsua_transport_config transportConfig;
        pjsua_transport_config_default(&transportConfig);

        pjsip_transport_type_e transportType = (pjsip_transport_type_e)transportConfiguration.transportType;
        pjsua_transport_id transportId;

        status = pjsua_transport_create(transportType, &transportConfig, &transportId);
        if (status != PJ_SUCCESS) {
            if (error != NULL) {
                *error = [NSError VSLUnderlyingError:nil
                   localizedDescriptionKey:NSLocalizedString(@"Could not add transport configuration", nil)
               localizedFailureReasonError:[NSString stringWithFormat:NSLocalizedString(@"PJSIP status code: %d", nil), status]
                               errorDomain:VSLEndpointErrorDomain
                                 errorCode:VSLEndpointErrorCannotAddTransportConfiguration];
            }
            return NO;
        }
    }

    // Start Endpoint.
    status = pjsua_start();
    if (status != PJ_SUCCESS) {
        [self destoryPJSUAInstance];
        if (error != NULL) {
            *error = [NSError VSLUnderlyingError:nil
               localizedDescriptionKey:NSLocalizedString(@"Could not start PJSIP Endpoint", nil)
           localizedFailureReasonError:[NSString stringWithFormat:NSLocalizedString(@"PJSIP status code: %d", nil), status]
                           errorDomain:VSLEndpointErrorDomain
                             errorCode:VSLEndpointErrorCannotStartPJSUA];
        }
        return NO;
    }
    DDLogInfo(@"PJSIP Endpoint started succesfully");
    self.endpointConfiguration = endpointConfiguration;
    self.state = VSLEndpointStarted;
    return YES;
}

- (BOOL)createPJThreadAndPoolwithError:(NSError * _Nullable __autoreleasing *)error {
    // Create a seperate thread
    pj_thread_desc aPJThreadDesc;
    if (!pj_thread_is_registered()) {
        pj_thread_t *pjThread;
        pj_status_t status = pj_thread_register(NULL, aPJThreadDesc, &pjThread);
        if (status != PJ_SUCCESS) {
            *error = [NSError VSLUnderlyingError:nil
               localizedDescriptionKey:NSLocalizedString(@"Could not create PJSIP thread", nil)
           localizedFailureReasonError:[NSString stringWithFormat:NSLocalizedString(@"PJSIP status code: %d", nil), status]
                           errorDomain:VSLEndpointErrorDomain
                             errorCode:VSLEndpointErrorCannotCreateThread];
            return NO;
        }
    }

    // Create pool for PJSUA.
    self.pjPool = pjsua_pool_create("VialerSIPLib-pjsua", 1000, 1000);
    return YES;
}

- (void)destoryPJSUAInstance {
    DDLogInfo(@"PJSUA was already running destroying old instance.");

    for (VSLAccount *account in self.accounts) {
        [account removeAllCalls];
    }

    if (!pj_thread_is_registered()) {
        pj_thread_desc aPJThreadDesc;
        pj_thread_t *pjThread;
        pj_status_t status = pj_thread_register(NULL, aPJThreadDesc, &pjThread);

        if (status != PJ_SUCCESS) {
            NSLog(@"Error registering thread at PJSUA");
        }
    }

    if (self.pjPool != NULL) {
        pj_pool_release([self pjPool]);
        self.pjPool = NULL;
    }

    // Destroy PJSUA.
    pj_status_t status = pjsua_destroy();

    if (status != PJ_SUCCESS) {
        DDLogError(@"Error stopping SIP Endpoint");
    }

    self.state = VSLEndpointStopped;
}

#pragma mark - Account functions

- (void)addAccount:(VSLAccount *)account {
    self.accounts = [self.accounts arrayByAddingObject:account];
}

- (void)removeAccount:(VSLAccount *)account {
    NSMutableArray *mutableArray = [self.accounts mutableCopy];
    [mutableArray removeObject:account];
    self.accounts = [mutableArray copy];
}

- (VSLAccount *)lookupAccount:(NSInteger)accountId {
    NSUInteger accountIndex = [self.accounts indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        VSLAccount *account = (VSLAccount *)obj;
        if (account.accountId == accountId && account.accountId != PJSUA_INVALID_ID) {
            return YES;
        }
        return NO;
    }];

    if (accountIndex != NSNotFound) {
        return [self.accounts objectAtIndex:accountIndex]; //TODO add more management
    } else {
        return nil;
    }
}

- (VSLAccount *)getAccountWithSipAccount:(NSString *)sipAccount {
    for (VSLAccount *account in self.accounts) {
        if (account.accountConfiguration.sipAccount == sipAccount) {
            return account;
        }
    }
    return nil;
}

#pragma mark - PJSUA callbacks

static void logCallBack(int level, const char *data, int len) {
    NSString *logString = [[NSString alloc] initWithUTF8String:data];

    // Strip time stamp from the front
    // TODO: check that the logmessage actually has a timestamp before removing.
    logString = [logString substringFromIndex:13];

    // The data obtained from the callback has a NewLine character at the end, remove it.
    unichar last = [logString characterAtIndex:[logString length] - 1];
    if ([[NSCharacterSet newlineCharacterSet] characterIsMember:last]) {
        logString = [logString substringToIndex:[logString length]-1];
    }

    DDLogVerbose(@"Level:%i %@", level, logString);
}

static void onCallState(pjsua_call_id callId, pjsip_event *event) {
    DDLogVerbose(@"Updated callState");

    pjsua_call_info callInfo;
    pjsua_call_get_info(callId, &callInfo);

    VSLAccount *account = [[VSLEndpoint sharedEndpoint] lookupAccount:callInfo.acc_id];
    if (account) {
        VSLCall *call = [account lookupCall:callId];
        if (call) {
            [call callStateChanged:callInfo];
        }
    }
}

static void onCallMediaState(pjsua_call_id call_id) {
    DDLogVerbose(@"Updated mediastate");

    pjsua_call_info callInfo;
    pjsua_call_get_info(call_id, &callInfo);

    VSLAccount *account = [[VSLEndpoint sharedEndpoint] lookupAccount:callInfo.acc_id];
    if (account) {
        VSLCall *call = [account lookupCall:call_id];
        if (call) {
            [call mediaStateChanged:callInfo];
        }
    }
}

static void onRegState(pjsua_acc_id acc_id) {
    DDLogVerbose(@"Updated regState");

    VSLAccount *account = [[VSLEndpoint sharedEndpoint] lookupAccount:acc_id];

    if (account) {
        [account accountStateChanged];
    }
}

static void onIncomingCall(pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata) {
    DDLogInfo(@"Incoming call");
    DDLogInfo(@"AccountID: %d", acc_id);

    VSLAccount *account = [[VSLEndpoint sharedEndpoint] lookupAccount:acc_id];

    if (account) {

        VSLCall *call = [VSLCall callWithId:call_id andAccountId:acc_id];
        if (call) {
            [account addCall:call];

            if ([VSLEndpoint sharedEndpoint].incomingCallBlock) {
                [VSLEndpoint sharedEndpoint].incomingCallBlock(call);
            }
        }
    }
}

//TODO: implement these

static void onCallTransferStatus(pjsua_call_id call_id, int st_code, const pj_str_t *st_text, pj_bool_t final, pj_bool_t *p_cont) {
    DDLogVerbose(@"Updated transfer");
}

static void onCallReplaced(pjsua_call_id old_call_id, pjsua_call_id new_call_id) {
    DDLogVerbose(@"call replaced");
}

static void onNatDetect(const pj_stun_nat_detect_result *res){
    DDLogVerbose(@"Updated natdetect");
}

# pragma mark - Utils


@end
