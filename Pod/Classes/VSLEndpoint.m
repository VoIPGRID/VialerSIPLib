//
//  VSLEndpoint.m
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import "VSLEndpoint.h"

#import "Constants.h"
#import "NSError+VSLError.h"
#import "NSString+PJString.h"
#import "VialerSIPLib.h"
#import "VSLCall.h"
#import "VSLCallManager.h"
#import "VSLLogging.h"
#import "VSLNetworkMonitor.h"
#import "VSLTransportConfiguration.h"

static NSString * const VSLEndpointErrorDomain = @"VialerSIPLib.VSLEndpoint.error";

static void logCallBack(int level, const char *data, int len);
static void onCallState(pjsua_call_id callId, pjsip_event *event);
static void onIncomingCall(pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata);
static void onCallMediaState(pjsua_call_id call_id);
static void onCallTransferStatus(pjsua_call_id call_id, int st_code, const pj_str_t *st_text, pj_bool_t final, pj_bool_t *p_cont);
static void onCallReplaced(pjsua_call_id old_call_id, pjsua_call_id new_call_id);
static void onRegState2(pjsua_acc_id acc_id, pjsua_reg_info *info);
static void onRegStarted2(pjsua_acc_id acc_id, pjsua_reg_info *info);
static void onNatDetect(const pj_stun_nat_detect_result *res);
static void onTransportState(pjsip_transport *tp, pjsip_transport_state state, const pjsip_transport_state_info *info);
static void onCallMediaEvent(pjsua_call_id call_id, unsigned med_idx, pjmedia_event *event);
static void onTxStateChange(pjsua_call_id call_id, pjsip_transaction *tx, pjsip_event *event);

static pjsip_transport *the_transport;

@interface VSLEndpoint()
@property (strong, nonatomic) VSLEndpointConfiguration *endpointConfiguration;
@property (strong, nonatomic) NSArray *accounts;
@property (assign) pj_pool_t *pjPool;
@property (assign) BOOL shouldReregisterAfterUnregister;
@property (strong, nonatomic) VSLNetworkMonitor *networkMonitor;
@property (nonatomic) BOOL onlyUseILBC;
@property (weak, nonatomic) VSLCallManager *callManager;
@property (nonatomic) BOOL monitoringCalls;
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

- (void)setState:(VSLEndpointState)state {
    if (_state != state) {
        _state = state;
        switch (_state) {
            case VSLEndpointStopped: {
                @try {
                    [[NSNotificationCenter defaultCenter] removeObserver:self name:VSLCallStateChangedNotification object:nil];
                } @catch (NSException *exception) {

                }

                @try {
                    [[NSNotificationCenter defaultCenter] removeObserver:self name:VSLCallDeallocNotification object: nil];
                } @catch(NSException *exceptiom) {

                }
                break;
            }
            case VSLEndpointStarting: {
                break;
            }
            case VSLEndpointStarted: {
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkMonitoring:) name:VSLCallStateChangedNotification object:nil];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callDealloc:) name:VSLCallDeallocNotification object:nil];
                break;
            }
        }
    }
}

- (VSLCallManager *)callManager {
    return [[VialerSIPLib sharedInstance] callManager];
}

- (VSLNetworkMonitor *)networkMonitor {
    if (!_networkMonitor) {
        VSLAccount *activeAccount;
        for (VSLAccount *account in self.accounts) {
            if ([account firstActiveCall]) {
                activeAccount = account;
                break;
            }
        }

        NSString *reachabilityServer = @"sipproxy.voipgrid.nl";
        if (activeAccount) {
            reachabilityServer = activeAccount.accountConfiguration.sipProxyServer;
        }
        _networkMonitor = [[VSLNetworkMonitor alloc] initWithHost:reachabilityServer];
    }
    return _networkMonitor;
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

    VSLLogDebug(@"Creating new PJSIP Endpoint instance.");
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
    endpointConfig.cb.on_reg_state2 = &onRegState2;
    endpointConfig.cb.on_reg_started2 = &onRegStarted2;
    endpointConfig.cb.on_nat_detect = &onNatDetect;
    endpointConfig.cb.on_transport_state = &onTransportState;
    endpointConfig.cb.on_call_media_event = &onCallMediaEvent;
    endpointConfig.cb.on_call_tsx_state = &onTxStateChange;
    endpointConfig.max_calls = (unsigned int)endpointConfiguration.maxCalls;
    endpointConfig.user_agent = endpointConfiguration.userAgent.pjString;

    // Configure the media information for the endpoint.
    pjsua_media_config mediaConfig;
    pjsua_media_config_default(&mediaConfig);
    mediaConfig.clock_rate = (unsigned int)endpointConfiguration.clockRate == 0 ? PJSUA_DEFAULT_CLOCK_RATE : (unsigned int)endpointConfiguration.clockRate;
    mediaConfig.snd_clock_rate = (unsigned int)endpointConfiguration.sndClockRate;

    // Initialize Endpoint.
    status = pjsua_init(&endpointConfig, &logConfig, &mediaConfig);
    if (status != PJ_SUCCESS) {
        [self destroyPJSUAInstance];
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
        [self destroyPJSUAInstance];
        if (error != NULL) {
            *error = [NSError VSLUnderlyingError:nil
                         localizedDescriptionKey:NSLocalizedString(@"Could not start PJSIP Endpoint", nil)
                     localizedFailureReasonError:[NSString stringWithFormat:NSLocalizedString(@"PJSIP status code: %d", nil), status]
                                     errorDomain:VSLEndpointErrorDomain
                                       errorCode:VSLEndpointErrorCannotStartPJSUA];
        }
        return NO;
    }

    pjsua_set_no_snd_dev();

    VSLLogInfo(@"PJSIP Endpoint started succesfully");
    self.endpointConfiguration = endpointConfiguration;
    self.state = VSLEndpointStarted;

    [self updateCodecs];

    return YES;
}

- (BOOL)createPJThreadAndPoolwithError:(NSError * _Nullable __autoreleasing *)error {
    // Create a seperate thread
    pj_thread_desc aPJThreadDesc;
    if (!pj_thread_is_registered()) {
        pj_thread_t *pjThread;
        pj_status_t status = pj_thread_register(NULL, aPJThreadDesc, &pjThread);
        if (status != PJ_SUCCESS) {
            if (error != NULL) {
                *error = [NSError VSLUnderlyingError:nil
                             localizedDescriptionKey:NSLocalizedString(@"Could not create PJSIP thread", nil)
                         localizedFailureReasonError:[NSString stringWithFormat:NSLocalizedString(@"PJSIP status code: %d", nil), status]
                                         errorDomain:VSLEndpointErrorDomain
                                           errorCode:VSLEndpointErrorCannotCreateThread];
            }
            return NO;
        }
    }

    // Create pool for PJSUA.
    self.pjPool = pjsua_pool_create("VialerSIPLib-pjsua", 1000, 1000);
    return YES;
}

- (void)destroyPJSUAInstance {
    VSLLogDebug(@"PJSUA was already running destroying old instance.");
    [self stopNetworkMonitoring];

    for (VSLAccount *account in self.accounts) {
        [account removeAllCalls];
        [self removeAccount:account];
    }

    if (!pj_thread_is_registered()) {
        pj_thread_desc aPJThreadDesc;
        pj_thread_t *pjThread;
        pj_status_t status = pj_thread_register(NULL, aPJThreadDesc, &pjThread);

        if (status != PJ_SUCCESS) {
            VSLLogError(@"Error registering thread at PJSUA");
        }
    }

    if (self.pjPool != NULL) {
        pj_pool_release(self->_pjPool);
    }
    
    // Destroy PJSUA.
    pj_status_t status = pjsua_destroy();
    if (status != PJ_SUCCESS) {
        VSLLogWarning(@"Error stopping SIP Endpoint");
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

- (VSLCall *)lookupCall:(NSInteger)callId {

    for (VSLAccount *account in self.accounts) {
        VSLCall *call = [account lookupCall:callId];
        if (call) {
            return call;
        }
    }
    return nil;
}

- (VSLAccount *)getAccountWithSipAccount:(NSString *)sipAccount {
    for (VSLAccount *account in self.accounts) {
        if ([account.accountConfiguration.sipAccount isEqualToString:sipAccount]) {
            return account;
        }
    }
    return nil;
}

#pragma mark - codecs

- (void)onlyUseILBC:(BOOL)activate {
    if (self.onlyUseILBC == activate) {
        return;
    }
    self.onlyUseILBC = activate;
    if (![self updateCodecs]) {
        self.onlyUseILBC = !activate;
    }
}

- (BOOL)updateCodecs {
    if (self.state != VSLEndpointStarted) {
        return NO;
    }

    const unsigned codecInfoSize = 64;
    pjsua_codec_info codecInfo[codecInfoSize];
    unsigned codecCount = codecInfoSize;
    pj_status_t status = pjsua_enum_codecs(codecInfo, &codecCount);
    if (status != PJ_SUCCESS) {
        VSLLogError(@"Error getting list of codecs");
        return NO;
    } else {
        for (NSUInteger i = 0; i < codecCount; i++) {
            NSString *codecIdentifier = [NSString stringWithPJString:codecInfo[i].codec_id];
            pj_uint8_t priority = [self priorityForCodec:codecIdentifier];
            status = pjsua_codec_set_priority(&codecInfo[i].codec_id, priority);
            if (status != PJ_SUCCESS) {
                VSLLogError(@"Error setting codec priority to the correct value");
                return NO;
            }
        }
    }
    return YES;
}

- (pj_uint8_t)priorityForCodec:(NSString *)identifier {
    NSDictionary *priorities;
    if (self.onlyUseILBC) {
        priorities = @{
                       // G711a
                       @"PCMA/8000/1":      @0,
                       // G722
                       @"G722/16000/1":     @0,
                       // iLBC
                       @"iLBC/8000/1":      @210,
                       // G711
                       @"PCMU/8000/1":      @0,
                       // Speex 8 kHz
                       @"speex/8000/1":     @0,
                       // Speex 16 kHz
                       @"speex/16000/1":    @0,
                       // Speex 32 kHz
                       @"speex/32000/1":    @0,
                       // GSM 8 kHZ
                       @"GSM/8000/1":       @0,
                       };

    } else {
        priorities = @{
                       // G711a
                       @"PCMA/8000/1":      @210,
                       // G722
                       @"G722/16000/1":     @209,
                       // iLBC
                       @"iLBC/8000/1":      @208,
                       // G711
                       @"PCMU/8000/1":      @0,
                       // Speex 8 kHz
                       @"speex/8000/1":     @0,
                       // Speex 16 kHz
                       @"speex/16000/1":    @0,
                       // Speex 32 kHz
                       @"speex/32000/1":    @0,
                       // GSM 8 kHZ
                       @"GSM/8000/1":       @0,
                       };
    }
    return (pj_uint8_t)[priorities[identifier] unsignedIntegerValue];
}

#pragma mark - PJSUA callbacks

static void logCallBack(int logLevel, const char *data, int len) {
    NSString *logString = [[NSString alloc] initWithUTF8String:data];

    // Strip time stamp from the front
    // TODO: check that the logmessage actually has a timestamp before removing.
    logString = [logString substringFromIndex:13];

    // The data obtained from the callback has a NewLine character at the end, remove it.
    unichar last = [logString characterAtIndex:[logString length] - 1];
    if ([[NSCharacterSet newlineCharacterSet] characterIsMember:last]) {
        logString = [logString substringToIndex:[logString length]-1];
    }

    switch (logLevel) {
        case 1:
            VSLLogError(@"%@", logString);
            break;
        case 2:
            VSLLogWarning(@"%@", logString);
            break;
        case 3:
            VSLLogInfo(@"%@", logString);
            break;
        case 4:
            VSLLogDebug(@"%@", logString);
            break;
        default:
            VSLLogVerbose(@"%@", logString);
            break;
    }
}

static void onCallState(pjsua_call_id callId, pjsip_event *event) {
    pjsua_call_info callInfo;
    pjsua_call_get_info(callId, &callInfo);

    VSLAccount *account = [[VSLEndpoint sharedEndpoint] lookupAccount:callInfo.acc_id];
    if (account) {
        VSLCall *call = [account lookupCall:callId];
        if (call) {
            [call callStateChanged:callInfo];
        } else {
            VSLLogWarning(@"Received updated CallState(%@) for UNKNOWN call(id: %d)", VSLCallStateString(callInfo.state) , callId);
        }
    }
}

static void onCallMediaState(pjsua_call_id call_id) {
    pjsua_call_info callInfo;
    pjsua_call_get_info(call_id, &callInfo);

    VSLAccount *account = [[VSLEndpoint sharedEndpoint] lookupAccount:callInfo.acc_id];
    if (account) {
        VSLCall *call = [account lookupCall:call_id];
        VSLLogVerbose(@"Received MediaState update for call:%@", call.uuid.UUIDString);
        if (call) {
            [call mediaStateChanged:callInfo];
        }
    }
}

/**
 *  We need to keep track of the current TCP transport in combination with
 *  a network monitor to be able to handle network/ip address changes.
 *  http://trac.pjsip.org/repos/wiki/IPAddressChange#iphone
 */
static void onRegStarted2(pjsua_acc_id acc_id, pjsua_reg_info *info) {
    VSLLogVerbose(@"onRegStarted2");
    pjsip_regc_info regc_info;
    pjsip_regc_get_info(info->regc, &regc_info);
    if ([VSLEndpoint sharedEndpoint].endpointConfiguration.hasTCPConfiguration) {
        if (the_transport != regc_info.transport) {
            releaseStoredTransport();
            /* Save transport instance so that we can close it later when
             * new IP address is detected.
             */
            VSLLogInfo(@"Saving transport");
            the_transport = regc_info.transport;
            pjsip_transport_add_ref(the_transport);
        }
    }
}

static void onRegState2(pjsua_acc_id acc_id, pjsua_reg_info *info) {
    VSLLogVerbose(@"onRegState2");
    
    if ([VSLEndpoint sharedEndpoint].endpointConfiguration.hasTCPConfiguration) {
        struct pjsip_regc_cbparam *rp = info->cbparam;
        
        releaseStoredTransport();
        if (rp->code/100 == 2 && rp->expiration > 0 && rp->contact_cnt > 0) {
            the_transport = rp->rdata->tp_info.transport;
            pjsip_transport_add_ref(the_transport);
        }
    }

    VSLAccount *account = [[VSLEndpoint sharedEndpoint] lookupAccount:acc_id];
    if (account) {
        [account accountStateChanged];
    }
}

static void onTransportState(pjsip_transport *tp, pjsip_transport_state state, const pjsip_transport_state_info *info) {
    VSLLogVerbose(@"onTransportState");
    if ([VSLEndpoint sharedEndpoint].endpointConfiguration.hasTCPConfiguration) {
        if (state == PJSIP_TP_STATE_DISCONNECTED && the_transport == tp) {
            releaseStoredTransport();
        }
        the_transport = tp;
        pjsip_transport_add_ref(tp);
    }
}

/* Callback on media events. Adjust renderer window size to original video size */
static void onCallMediaEvent(pjsua_call_id call_id,
                             unsigned med_idx,
                             pjmedia_event *event) {
#if PJSUA_HAS_VIDEO
    if (event->type == PJMEDIA_EVENT_FMT_CHANGED) {
        char event_name[5];
        VSLLogVerbose(@"Event Media %s", pjmedia_fourcc_name(event->type, event_name));
        pjsua_call_info ci;
        pjsua_vid_win_id wid;
        pjmedia_rect_size size;
        
        pjsua_call_get_info(call_id, &ci);
        
        if ((ci.media[med_idx].type == PJMEDIA_TYPE_VIDEO) &&
            (ci.media[med_idx].dir & PJMEDIA_DIR_DECODING))
        {
            wid = ci.media[med_idx].stream.vid.win_in;
            size = event->data.fmt_changed.new_fmt.det.vid.size;
            NSDictionary *userInfo = @{VSLNotificationUserInfoCallIdKey:@(call_id),
                                       VSLNotificationUserInfoWindowIdKey:@(wid),
                                       VSLNotificationUserInfoWindowSizeKey:[NSValue valueWithCGSize:(CGSize){size.w, size.h}]};
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:VSLNotificationUserInfoVideoSizeRenderKey object:nil userInfo:userInfo];
            });
        }
    }
#endif
}

static void onTxStateChange(pjsua_call_id call_id, pjsip_transaction *tx, pjsip_event *event) {
    pjsua_call_info callInfo;
    pjsua_call_get_info(call_id, &callInfo);
    
    // When a call is in de early state it is possible to check if
    // the call has been completed elsewhere or if the original caller
    // has ended the call.
    if (callInfo.state == VSLCallStateEarly) {
        [VSLEndpoint wasCallMissed:call_id pjsuaCallInfo:callInfo pjsipEvent:event];
    }
}

 void onIncomingCall(pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata) {
    VSLEndpoint *endpoint = [VSLEndpoint sharedEndpoint];
    VSLAccount *account = [endpoint lookupAccount:acc_id];
    if (account) {
        VSLLogInfo(@"Detected inbound call(%d) for account:%d", call_id, acc_id);
        VSLCall *call = [[VSLCall alloc] initInboundCallWithCallId:call_id account:account];
        if (call) {
            [[[VialerSIPLib sharedInstance] callManager] addCall:call];
            if ([VSLEndpoint sharedEndpoint].incomingCallBlock) {
                [VSLEndpoint sharedEndpoint].incomingCallBlock(call);
            }
        }
    } else {
        VSLLogWarning(@"Could not accept incoming call. No account found with ID:%d", acc_id);
    }
}

static void onCallTransferStatus(pjsua_call_id callId, int statusCode, const pj_str_t *statusText, pj_bool_t final, pj_bool_t *continueNotifications) {
    VSLCall *call = [[VSLEndpoint sharedEndpoint] lookupCall:callId];
    if (call) {
        [call callTransferStatusChangedWithStatusCode:statusCode statusText:[NSString stringWithPJString:*statusText] final:final == 1];
    }
}

/**
 *  Release the current TCP transport.
 */
static void releaseStoredTransport() {
    if (the_transport) {
        VSLLogDebug(@"Releasing transport");
        pjsip_transport_dec_ref(the_transport);
        the_transport = NULL;
    }
}

/**
 *  Shutsdown the current TCP transport.
 *
 *  @return YES if succesfull
 */
- (BOOL)shutdownTransport {
    if (!self.endpointConfiguration.hasTCPConfiguration) {
        return NO;
    }


    if (self.endpointConfiguration.hasTCPConfiguration && the_transport) {
        pj_status_t status;
        status = pjsip_transport_shutdown(the_transport);
        VSLLogInfo(@"Shuting down transport");
        if (status != PJ_SUCCESS) {
            VSLLogWarning(@"Transport shutdown error");
            return NO;
        }
        releaseStoredTransport();
    }
    return YES;
}

- (void)callDealloc:(NSNotification *)notification {
    VSLLogError(@"Call dealloc");
    for (VSLAccount *account in self.accounts) {
        if (![self.callManager firstActiveCallForAccount:account]) {
            NSArray *calls = [self.callManager callsForAccount:account];
            if (calls.count == 0) {
                NSError *error;
                [account unregisterAccount:&error];
            }
        }
    }
}

#pragma mark - Reachability detection


/**
 *  Start the network monitor if the call is not disconnected
 *  which will inform us about a network change so we can bring down
 *  and reinitialize the TCP transport.
 */
- (void)checkNetworkMonitoring:(NSNotification *)notification {
    VSLCall *call = notification.userInfo[VSLNotificationUserInfoCallKey];

    switch (call.callState) {
        case VSLCallStateDisconnected: {
            [self stopNetworkMonitoring];
            break;
        }
        default: {
            if (!self.monitoringCalls) {
                for (VSLAccount *account in self.accounts) {
                    if ([account firstActiveCall]) {
                        VSLLogVerbose(@"Starting network monitor");
                        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ipAddressChanged:) name:VSLNetworkMonitorChangedNotification object:nil];
                        [self.networkMonitor startMonitoring];
                        self.monitoringCalls = YES;
                        break;
                    }
                }
            }
        }
    }
}

/**
 *  Stop the network monitor. The monitor will only be stopped when there are no active calls
 *  found for any account.
 */
- (void)stopNetworkMonitoring {
    BOOL activeCallForAnyAccount = NO;
    // Try to find an account which has an active call.
    for (VSLAccount *account in self.accounts) {
        if ([account firstActiveCall]) {
            activeCallForAnyAccount = YES;
            break;
        }
    }

    // If there is no active call anymore for any account, stop the reachability monitoring
    if (!activeCallForAnyAccount) {
        VSLLogVerbose(@"No active calls for any account, stopping network monitor");
        @try {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:VSLNetworkMonitorChangedNotification object:nil];
        } @catch (NSException *exception) {
            VSLLogWarning(@"Exception on removing the reachability change notification.");
        }
        [self.networkMonitor stopMonitoring];
        self.networkMonitor = nil;
        self.monitoringCalls = NO;
    }
}

/**
 *  Register account again if network has changed connection.
 *
 *  To prevent registration to quickly or to often, we wait for a second before actually sending the registration.
 *  This is needed because switching to or between mobile networks can happen multiple times in a short time.
 *
 *  @param notification The notification which lead to this function being invoked over GCD.
 */
- (void)ipAddressChanged:(NSNotification *)notification {
    VSLLogInfo(@"network changed");
    if (self.state == VSLEndpointStarted) {
        if ([self shutdownTransport]) {
            for (VSLAccount *account in self.accounts) {
                [account reregisterAccount];
            }
        }
    }
}

+ (void)wasCallMissed:(pjsua_call_id)call_id pjsuaCallInfo:(pjsua_call_info)callInfo pjsipEvent:(pjsip_event*)event {
    // Get the packet that belongs to RX transaction.
    NSString *packet =  [NSString stringWithFormat:@"%s", event->body.tsx_state.src.rdata->pkt_info.packet];
    
    if (![packet isEqualToString: @""]) {
        NSString *callCompletedElsewhere = @"Call completed elsewhere";
        NSString *originatorCancel = @"ORIGINATOR_CANCEL";
        VSLCallTerminateReason reason = VSLCallTerminateReasonUnknown;
        
        if ([packet rangeOfString:callCompletedElsewhere].location != NSNotFound) {
            // The call has been completed elsewhere.
            reason = VSLCallTerminateReasonCallCompletedElsewhere;
        } else if ([packet rangeOfString:originatorCancel].location != NSNotFound) {
            //The original caller has hung up.
            reason = VSLCallTerminateReasonOriginatorCancel;
        }
        
        if ([VSLEndpoint sharedEndpoint].missedCallBlock && reason != VSLCallTerminateReasonUnknown) {
            VSLAccount *account = [[VSLEndpoint sharedEndpoint] lookupAccount:callInfo.acc_id];
            VSLCall *call = [account lookupCall:call_id];
            if (call) {
                call.terminateReason = reason;
                VSLLogDebug(@"Call was terminated for reason: %@", VSLCallTerminateReasonString(reason));
                [VSLEndpoint sharedEndpoint].missedCallBlock(call);
            } else {
                VSLLogWarning(@"Received updated CallState(%@) for UNKNOWN call(id: %d)", VSLCallStateString(callInfo.state) , call_id);
            }
        }
    }
}

//TODO: implement these

static void onCallReplaced(pjsua_call_id old_call_id, pjsua_call_id new_call_id) {
    VSLLogVerbose(@"Call replaced");
}

static void onNatDetect(const pj_stun_nat_detect_result *res){
    if (res->status != PJ_SUCCESS) {
        VSLLogWarning(@"NAT detection failed %@", res->status ? @"YES" : @"NO");
    } else {
        VSLLogDebug(@"NAT detected as %s", res->nat_type_name);
    }
}


@end
