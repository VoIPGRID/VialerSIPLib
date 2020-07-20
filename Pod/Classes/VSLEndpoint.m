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
#import "VSLAudioCodecs.h"
#import "VSLLogging.h"
#import "VSLNetworkMonitor.h"
#import "VSLIpChangeConfiguration.h"
#import "VSLTransportConfiguration.h"
#import "VSLVideoCodecs.h"

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
static void onCallMediaEvent(pjsua_call_id call_id, unsigned med_idx, pjmedia_event *event);
static void onTxStateChange(pjsua_call_id call_id, pjsip_transaction *tx, pjsip_event *event);
static void onIpChangeProgress(pjsua_ip_change_op op, pj_status_t status, const pjsua_ip_change_op_info *info);
static void onTransportStateChanged(pjsip_transport *tp, pjsip_transport_state state, const pjsip_transport_state_info *info);

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
            case VSLEndpointClosing:
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
            if ([self.callManager firstCallForAccount:account]) {
                activeAccount = account;
                break;
            }
        }

        NSString *reachabilityServer = @"sipproxy.voipgrid.nl";
        if (activeAccount) {
            if (!activeAccount.accountConfiguration.sipProxyServer || [activeAccount.accountConfiguration.sipProxyServer length] == 0)
                reachabilityServer = activeAccount.accountConfiguration.sipDomain;
            else
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


    // Create worker thread for pjsip.
    NSError *threadError;
    if (![self createPJSIPThreadWithError:&threadError]) {
        *error = threadError;
        return NO;
    }

    // Create PJSUA on the main thread to make all subsequent calls from the main thread.
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

    [self createPoolForPJSIP];

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
    endpointConfig.cb.on_call_media_event = &onCallMediaEvent;
    endpointConfig.cb.on_call_tsx_state = &onTxStateChange;
    endpointConfig.cb.on_ip_change_progress = &onIpChangeProgress;
    endpointConfig.cb.on_transport_state = &onTransportStateChanged;

    endpointConfig.max_calls = (unsigned int)endpointConfiguration.maxCalls;
    endpointConfig.user_agent = endpointConfiguration.userAgent.pjString;

    if (endpointConfiguration.stunConfiguration) {
        endpointConfig.stun_srv_cnt = endpointConfiguration.stunConfiguration.numOfStunServers;
        int i = 0;
        for (NSString* stunServer in endpointConfiguration.stunConfiguration.stunServers){
            endpointConfig.stun_srv[i] = [stunServer pjString];
            i++;
        }
    }

    // Configure the media information for the endpoint.
    pjsua_media_config mediaConfig;
    pjsua_media_config_default(&mediaConfig);
    mediaConfig.clock_rate = (unsigned int)endpointConfiguration.clockRate == 0 ? PJSUA_DEFAULT_CLOCK_RATE : (unsigned int)endpointConfiguration.clockRate;
    mediaConfig.snd_clock_rate = (unsigned int)endpointConfiguration.sndClockRate;
    mediaConfig.has_ioqueue = PJ_TRUE;
    mediaConfig.thread_cnt = 1;
    mediaConfig.no_vad = PJ_TRUE;

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


        if (endpointConfiguration.hasTLSConfiguration) {
            // FYI transportConfig.tls_setting.method defaults to PJSIP_SSL_UNSPECIFIED_METHOD > PJSIP_SSL_DEFAULT_METHOD > PJSIP_TLSV1_METHOD
            transportConfig.tls_setting.method = PJSIP_TLSV1_2_METHOD;
        }
        
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

    [self updateAudioCodecs];
    [self updateVideoCodecs];
    
    return YES;
}

- (BOOL)createPJSIPThreadWithError:(NSError * _Nullable __autoreleasing *)error {
    // Create a seperate thread
    pj_thread_desc aPJThreadDesc;
    if (!pj_thread_is_registered()) {
        pj_thread_t *pjThread;
        pj_status_t status = pj_thread_register("VialerPJSIP", aPJThreadDesc, &pjThread);
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

    return YES;
}

- (void)createPoolForPJSIP {
    // Create pool for PJSUA.
    self.pjPool = pjsua_pool_create("VialerSIPLib-pjsua", 1000, 1000);
}

- (void)destroyPJSUAInstance {
    VSLLogDebug(@"PJSUA was already running destroying old instance.");
    self.state = VSLEndpointClosing;
    [self stopNetworkMonitoring];
    [self.callManager endAllCalls];

    for (VSLAccount *account in self.accounts) {
        [self removeAccount:account];
    }

    if (!pj_thread_is_registered()) {
        pj_thread_desc aPJThreadDesc;
        pj_thread_t *pjThread;
        pj_status_t status = pj_thread_register("VialerPJSIP", aPJThreadDesc, &pjThread);

        if (status != PJ_SUCCESS) {
            char statusmsg[PJ_ERR_MSG_SIZE];
            pj_strerror(status, statusmsg, sizeof(statusmsg));
            VSLLogError(@"Error registering thread at PJSUA, status: %s", statusmsg);
        }
    }

    if (self.pjPool != NULL) {
        pj_pool_release(self.pjPool);
    }
    
    // Destroy PJSUA.
    pj_status_t status = pjsua_destroy();
    if (status != PJ_SUCCESS) {
        char statusmsg[PJ_ERR_MSG_SIZE];
        pj_strerror(status, statusmsg, sizeof(statusmsg));
        VSLLogWarning(@"Error stopping SIP Endpoint, status: %s", statusmsg);
    }

    self.state = VSLEndpointStopped;
}

- (BOOL)updateCodecConfiguration:(VSLCodecConfiguration *)codecConfiguration {
    if (self.state != VSLEndpointStarted) {
        return NO;
    }

    self.endpointConfiguration.codecConfiguration = codecConfiguration;
    [self updateAudioCodecs];
    [self updateVideoCodecs];

    return YES;
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
    return [self.callManager callWithCallId:callId];
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

-(BOOL)updateAudioCodecs {
    if (self.state != VSLEndpointStarted) {
        return NO;
    }

    const unsigned audioCodecInfoSize = 64;
    pjsua_codec_info audioCodecInfo[audioCodecInfoSize];
    unsigned audioCodecCount = audioCodecInfoSize;
    
    // Register thread if needed.
    NSError *threadError;
    if (![self createPJSIPThreadWithError:&threadError]) {
        VSLLogError(@"Error registering the thread for PJSIP: %@", threadError);
        return NO;
    }
    
    pj_status_t status = pjsua_enum_codecs(audioCodecInfo, &audioCodecCount);
    if (status != PJ_SUCCESS) {
        char statusmsg[PJ_ERR_MSG_SIZE];
        pj_strerror(status, statusmsg, sizeof(statusmsg));
        VSLLogError(@"Error getting list of audio codecs, status: %s", statusmsg);
        return NO;
    }

    for (NSUInteger i = 0; i < audioCodecCount; i++) {
        NSString *codecIdentifier = [NSString stringWithPJString:audioCodecInfo[i].codec_id];
        pj_uint8_t priority = [self priorityForAudioCodec:codecIdentifier];
        pj_str_t codecId = audioCodecInfo[i].codec_id;
        status = pjsua_codec_set_priority(&codecId, priority);
        [self updateOpusSettings:codecId];
        if (status != PJ_SUCCESS) {
            char statusmsg[PJ_ERR_MSG_SIZE];
            pj_strerror(status, statusmsg, sizeof(statusmsg));
            VSLLogError(@"Error setting codec priority to the correct value, status: %s", statusmsg);
            return NO;
        }
    }
    return YES;
}

-(pj_uint8_t)priorityForAudioCodec:(NSString *)identifier {
    NSUInteger priority = 0;
    for (VSLAudioCodecs* audioCodec in self.endpointConfiguration.codecConfiguration.audioCodecs) {
        if ([VSLAudioCodecString(audioCodec.codec) isEqualToString:identifier]) {
            priority = audioCodec.priority;
            return (pj_uint8_t)priority;
        }
    }
    return (pj_uint8_t)priority;
}

- (void)updateOpusSettings:(pj_str_t)codecId {
    for (VSLAudioCodecs* audioCodec in self.endpointConfiguration.codecConfiguration.audioCodecs) {
        if ([VSLAudioCodecString(audioCodec.codec) isEqualToString:VSLAudioCodecString(VSLAudioCodecOpus)]) {
            VSLOpusConfiguration *opusConfiguration = self.endpointConfiguration.codecConfiguration.opusConfiguration;
            pjmedia_codec_mgr *endpointMgr = [self getPjMediaCodecManager];

            unsigned count = 1;

            const pjmedia_codec_info *codecInfo;
            pjmedia_codec_param param;
            pjmedia_codec_opus_config opus_cfg;

            pjmedia_codec_mgr_find_codecs_by_id(endpointMgr, &codecId, &count, &codecInfo, NULL);
            pjmedia_codec_mgr_get_default_param(endpointMgr, codecInfo, &param);
            pjmedia_codec_opus_get_config(&opus_cfg);
            
            // Set VAD
            param.setting.vad = 0;

            // Set sample rate
            opus_cfg.sample_rate = opusConfiguration.sampleRate;
            opus_cfg.cbr = opusConfiguration.constantBitRate ? PJ_TRUE : PJ_FALSE;
            opus_cfg.frm_ptime = opusConfiguration.frameDuration;
            opus_cfg.complexity = (int)opusConfiguration.complexity;

            pjmedia_codec_opus_set_default_param(&opus_cfg, &param);
        }
    }
}

-(pjmedia_codec_mgr *)getPjMediaCodecManager {
    return pjmedia_endpt_get_codec_mgr(pjsua_get_pjmedia_endpt());
}

-(BOOL)updateVideoCodecs {
    if (self.state != VSLEndpointStarted) {
        return NO;
    }

    const unsigned videoCodecInfoSize = 64;
    pjsua_codec_info videoCodecInfo[videoCodecInfoSize];
    unsigned videoCodecCount = videoCodecInfoSize;
    pj_status_t status = pjsua_vid_enum_codecs(videoCodecInfo, &videoCodecCount);
    if (status != PJ_SUCCESS) {
        char statusmsg[PJ_ERR_MSG_SIZE];
        pj_strerror(status, statusmsg, sizeof(statusmsg));
        VSLLogError(@"Error getting list of video codecs, status: %d", statusmsg);
        return NO;
    } else {
        for (NSUInteger i = 0; i < videoCodecCount; i++) {
            NSString *codecIdentifier = [NSString stringWithPJString:videoCodecInfo[i].codec_id];
            pj_uint8_t priority = [self priorityForVideoCodec:codecIdentifier];
            
            status = pjsua_vid_codec_set_priority(&videoCodecInfo[i].codec_id, priority);

            if (priority > 0) {
                pjmedia_vid_codec_param param;
                pjsua_vid_codec_get_param(&videoCodecInfo[i].codec_id, &param);
                param.ignore_fmtp = PJ_TRUE;
                param.enc_fmt.det.vid.size.w = 288;
                param.enc_fmt.det.vid.size.h = 352;
                param.enc_fmt.det.vid.fps.num = 20;
                param.enc_fmt.det.vid.fps.denum = 1;
                param.dec_fmt.det.vid.size.w = 1920;
                param.dec_fmt.det.vid.size.h = 1920;
                pjsua_vid_codec_set_param(&videoCodecInfo[i].codec_id, &param);

                if (status != PJ_SUCCESS) {
                    char statusmsg[PJ_ERR_MSG_SIZE];
                    pj_strerror(status, statusmsg, sizeof(statusmsg));
                    DDLogError(@"Error setting video codec priority to the correct value, status: %s", statusmsg);
                    return NO;
                }
            }
        }
    }

    return YES;
}

-(pj_uint8_t)priorityForVideoCodec:(NSString *)identifier {
    NSUInteger priority = 0;
    for (VSLVideoCodecs* videoCodec in self.endpointConfiguration.codecConfiguration.videoCodecs) {
        if ([VSLVideoCodecString(videoCodec.codec) isEqualToString:identifier] && !self.endpointConfiguration.disableVideoSupport) {
            priority = videoCodec.priority;
            return (pj_uint8_t)priority;
        }
    }
    return (pj_uint8_t)priority;
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
        logString = [logString substringToIndex:[logString length] - 1];
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

    NSString *searchedString = logString;
    NSRange searchedRange = NSMakeRange(0, [searchedString length]);
    NSString *pattern = @"(?:.*)/([A-Z]+)/(?:.*)SIP/2.0 ([4|5]{1}[0-9]{2}) ([A-Za-z ]+)?(?:.*)Call-ID: ([A-Za-z0-9-@.]+)?";
    NSError *error = nil;

    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern: pattern options:NSRegularExpressionDotMatchesLineSeparators error:&error];
    NSArray* matches = [regex matchesInString:searchedString options:0 range: searchedRange];
    for (NSTextCheckingResult* match in matches) {
        NSString *method = [searchedString substringWithRange:[match rangeAtIndex:1]];
        NSString *statusCode = [searchedString substringWithRange:[match rangeAtIndex:2]];
        NSString *statusMessage = [searchedString substringWithRange:[match rangeAtIndex:3]];
        NSString *callId = [searchedString substringWithRange:[match rangeAtIndex:4]];

        if (![method isEqualToString:@"REGISTER"]) {
            NSDictionary *notificationUserInfo = @{
                                                   VSLNotificationUserInfoErrorStatusCodeKey : statusCode,
                                                   VSLNotificationUserInfoErrorStatusMessageKey: statusMessage,
                                                   VSLNotificationUserInfoCallIdKey: callId
                                                   };
            [[NSNotificationCenter defaultCenter] postNotificationName:VSLCallErrorDuringSetupCallNotification
                                                                object:nil
                                                              userInfo:notificationUserInfo];
        }
    }

}

/**
 * Notify application when call state has changed.
 */
static void onCallState(pjsua_call_id callId, pjsip_event *event) {
    pjsua_call_info callInfo;
    pjsua_call_get_info(callId, &callInfo);

    VSLLogVerbose(@"PJSUA callback: call state changed to %@.", VSLCallStateString(callInfo.state));
    
    VSLAccount *account = [[VSLEndpoint sharedEndpoint] lookupAccount:callInfo.acc_id];
    if (account) {
        VSLCall *call = [[VSLEndpoint sharedEndpoint].callManager callWithCallId:callId];
        if (call) {
            [call callStateChanged:callInfo];
        } else {
            VSLLogWarning(@"Received updated CallState(%@) for UNKNOWN call(id: %d)", VSLCallStateString(callInfo.state) , callId);
        }
    }
}

/**
 * Notify application when media state in the call has changed.
 */
static void onCallMediaState(pjsua_call_id call_id) {
    VSLLogVerbose(@"PJSUA callback: media state in the call has changed.");
    pjsua_call_info callInfo;
    pjsua_call_get_info(call_id, &callInfo);

    VSLAccount *account = [[VSLEndpoint sharedEndpoint] lookupAccount:callInfo.acc_id];
    if (account) {
        VSLCall *call = [[VSLEndpoint sharedEndpoint].callManager callWithCallId:call_id];
        VSLLogVerbose(@"Received MediaState update for call:%@", call.uuid.UUIDString);
        if (call) {
            [call mediaStateChanged:callInfo];
        }
    }
}

/**
 * Notify application when registration or unregistration has been initiated.
 */
static void onRegStarted2(pjsua_acc_id acc_id, pjsua_reg_info *info) {
    VSLLogVerbose(@"PJSUA callback: registration or unregistration has been initiated.");
}

/**
 * Notify application when registration status has changed.
 */
static void onRegState2(pjsua_acc_id acc_id, pjsua_reg_info *info) {
    VSLLogVerbose(@"PJSUA callback: registration status has changed.");

    VSLAccount *account = [[VSLEndpoint sharedEndpoint] lookupAccount:acc_id];
    if (account) {
        [account accountStateChanged];
    }

    if ([VSLEndpoint sharedEndpoint].ipChangeInProgress) {
        // When disableVideoSupport is on reinivite the calls again. And in the reinivite
        // disable the video stream. Otherwise the response is an 488 Not Acceptatble here.
        // When videosupport has been disabled in the PBX.
        if ([VSLEndpoint sharedEndpoint].endpointConfiguration.disableVideoSupport) {
            VSLIpChangeConfiguration *ipChangeConfiguration = [VSLEndpoint sharedEndpoint].endpointConfiguration.ipChangeConfiguration;
            VSLAccount *account = [[VSLEndpoint sharedEndpoint] lookupAccount:acc_id];
            if (ipChangeConfiguration) {
                switch (ipChangeConfiguration.ipChangeCallsUpdate) {
                    case VSLIpChangeConfigurationIpChangeCallsReinvite:
                        VSLLogInfo(@"Do a reinvite for all calls of account: %d", acc_id);
                        [[[VSLEndpoint sharedEndpoint] callManager] reinviteActiveCallsForAccount:account];
                        break;
                    case VSLIpChangeConfigurationIpChangeCallsUpdate:
                        // Do nothing. Update is not implemented by Asterisk.
                        break;
                    case VSLIpChangeConfigurationIpChangeCallsDefault:
                        // Do nothing.
                        break;
                }
            }
        }
    }
}

/**
 * Notification about media events such as video notifications. Adjust renderer window size to original video size.
 */
static void onCallMediaEvent(pjsua_call_id call_id, unsigned med_idx, pjmedia_event *event) {
    VSLLogVerbose(@"PJSUA callback: media event.");
    
    #if PJSUA_HAS_VIDEO
        if (event->type == PJMEDIA_EVENT_FMT_CHANGED) {
            char event_name[5];
            VSLLogVerbose(@"Media event %s", pjmedia_fourcc_name(event->type, event_name));
            pjsua_call_info ci;
            pjsua_vid_win_id wid;
            pjmedia_rect_size size;

            pjsua_call_get_info(call_id, &ci);

            if (ci.media[med_idx].type == PJMEDIA_TYPE_VIDEO && ci.media[med_idx].dir & PJMEDIA_DIR_DECODING) {
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

/**
 * This is a general notification callback which is called whenever a transaction within the call has changed state.
 */
static void onTxStateChange(pjsua_call_id call_id, pjsip_transaction *tx, pjsip_event *event) {
    VSLLogVerbose(@"PJSUA callback: transaction within the call has changed state.");
    pjsua_call_info callInfo;
    pjsua_call_get_info(call_id, &callInfo);

    // When a call is in de early state it is possible to check if
    // the call has been completed elsewhere or if the original caller
    // has ended the call.
    if (callInfo.state == VSLCallStateEarly) {
        [VSLEndpoint wasCallMissed:call_id pjsuaCallInfo:callInfo pjsipEvent:event];
    }
}

/**
 * Notify application on incoming call, a SIP INVITE is received.
 */
static void onIncomingCall(pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata) {
    VSLLogVerbose(@"PJSUA callback: incoming call.");
    VSLEndpoint *endpoint = [VSLEndpoint sharedEndpoint];
    VSLAccount *account = [endpoint lookupAccount:acc_id];
    if (account) {
        VSLLogInfo(@"Detected inbound call(%d) for account:%d", call_id, acc_id); // call_id is [0..VSLEndpointConfigurationMaxCalls]
        
        pjsua_call_info callInfo;
        pjsua_call_get_info(call_id, &callInfo);
        
        VSLCallManager *callManager = [VialerSIPLib sharedInstance].callManager;
        VSLCall *call = [callManager lastCallForAccount:account]; // TODO: safe to say that the last one is the right one?
     
        if (call) {
            call.callId = call_id;
            call.invite = [[SipInvite alloc] initWithInvitePacket:rdata->pkt_info.packet];

            // Answer 180 to the server so it will create a tone signalling the caller that the remote side is ringing.
            pjsua_call_answer(call_id, 180, NULL, NULL);
            
            if ([VSLEndpoint sharedEndpoint].incomingCallBlock) {
                [VSLEndpoint sharedEndpoint].incomingCallBlock(call);
            }
        } else {
            VSLLogWarning(@"Could not find a call with if %d.", call_id);
        }
        call = nil;
    } else {
        VSLLogWarning(@"Could not accept incoming call. No account found with ID:%d", acc_id);
    }
}

/**
 * Notify application of the status of previously sent call transfer request.
 */
static void onCallTransferStatus(pjsua_call_id callId, int statusCode, const pj_str_t *statusText, pj_bool_t final, pj_bool_t *continueNotifications) {
    VSLLogVerbose(@"PJSUA callback: the status of previously sent call transfer request.");
    VSLCall *call = [[VSLEndpoint sharedEndpoint].callManager callWithCallId:callId];
    if (call) {
        [call callTransferStatusChangedWithStatusCode:statusCode statusText:[NSString stringWithPJString:*statusText] final:final == 1];
    }
}

- (void)callDealloc:(NSNotification *)notification {
    if (!self.endpointConfiguration.unregisterAfterCall || self.state != VSLEndpointStarted) {
        // Don't remove (unregister) transports after the call ended, or when the endpoint didn't start at all.
        return;
    }

    // Unregister accounts that have no active calls.
    for (VSLAccount *account in self.accounts) {
        if (![self.callManager firstActiveCallForAccount:account]) {
            NSArray *calls = [self.callManager callsForAccount:account];
            if (calls.count == 0) {
                NSError *error;
                [account unregisterAccount:&error];  // TODO: I think the wish is to unregister an account when it has not got 1 call active. Does this for-if-if achieve that?
            }
        }
    }
    
    if ([[VSLEndpoint sharedEndpoint].endpointConfiguration hasTCPConfiguration] || [[VSLEndpoint sharedEndpoint].endpointConfiguration hasTLSConfiguration]) {  // Since UDP transports don't recreate automatically, only remove TLS / TCP transports.
        // Remove all current transports.
        pjsua_transport_id transportIds[32];
        unsigned count = PJ_ARRAY_SIZE(transportIds);
        
        pj_status_t status = pjsua_enum_transports (transportIds, &count);

        if (status == PJ_SUCCESS && count > 1) { // TODO: why not > 0?
            for (int i = 1; i < count; i++) {
                pjsua_transport_id tId = transportIds[i];
                pjsua_transport_info info;
                pj_status_t status = pjsua_transport_get_info(tId, &info);

                if (status == PJ_SUCCESS) {
                    // TODO: It looks like there is nothing destroyed.
                    // Call pjsip_transport_shutdown or pjsua_transport_close() for each tId? https://trac.pjsip.org/repos/ticket/1840 '2018: need to deprecate this API'.
                    VSLLogInfo(@"SUCCESS: Destroyed transport: %d", i);
                } else {
                    VSLLogError(@"FAILED: Destroyed transport: %d", i);
                }
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
    VSLCallState callState = [notification.userInfo[VSLNotificationUserInfoCallStateKey] intValue];

    switch (callState) {
        case VSLCallStateDisconnected: {
            [self stopNetworkMonitoring];
            break;
        }
        case VSLCallStateConfirmed: {
            if (!self.monitoringCalls) {
                for (VSLAccount *account in self.accounts) {
                    if ([self.callManager firstCallForAccount:account]) {
                        VSLLogVerbose(@"Starting network monitor");
                        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ipAddressChanged:) name:VSLNetworkMonitorChangedNotification object:nil];
                        [self.networkMonitor startMonitoring];
                        self.monitoringCalls = YES;
                        break;
                    }
                }
            }
        }
        case VSLCallStateNull:
        case VSLCallStateCalling:
        case VSLCallStateIncoming:
        case VSLCallStateEarly:
        case VSLCallStateConnecting: {
            // Do nothing.
            break;
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
        if ([self.callManager firstCallForAccount:account]) {
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
 *  To prevent registration to quickly or to often, we wait for some time before actually sending the registration.
 *  This is needed because switching to or between mobile networks can happen multiple times in a short time.
 *
 *  @param notification The notification which lead to this function being invoked over GCD.
 */
- (void)ipAddressChanged:(NSNotification *)notification {
    pjsua_ip_change_param param;
    pjsua_ip_change_param_default(&param);
    param.restart_lis_delay = 100; //msec
    param.restart_listener = PJ_TRUE;

    pj_status_t status = pjsua_handle_ip_change(&param);
    if (status != PJ_SUCCESS) {
        char statusmsg[PJ_ERR_MSG_SIZE];
        pj_strerror(status, statusmsg, sizeof(statusmsg));
        VSLLogError(@"Error handling ip change, status: %s", statusmsg);
    }
}

static void onIpChangeProgress(pjsua_ip_change_op op, pj_status_t status, const pjsua_ip_change_op_info *info) {
    VSLLogInfo(@"onIpChangeProgress:");
    
    [VSLEndpoint sharedEndpoint].ipChangeInProgress = YES;
    
    char statusmsg[PJ_ERR_MSG_SIZE];
    pj_strerror(status, statusmsg, sizeof(statusmsg));

    switch (op) {
        case PJSUA_IP_CHANGE_OP_NULL: {
            VSLLogDebug(@"Hasn't start ip change process, status: %s", statusmsg);
            break;
        }
        case PJSUA_IP_CHANGE_OP_RESTART_LIS: {
            VSLLogDebug(@"The restart listener process, status: %s", statusmsg);
            break;
        }
        case PJSUA_IP_CHANGE_OP_ACC_SHUTDOWN_TP: {
            VSLLogDebug(@"The shutdown transport process, statust: %s", statusmsg);
            break;
        }
        case PJSUA_IP_CHANGE_OP_ACC_UPDATE_CONTACT: {
            VSLLogDebug(@"The update contact process, status: %s", statusmsg);
            break;
        }
        case PJSUA_IP_CHANGE_OP_ACC_HANGUP_CALLS: {
            VSLLogDebug(@"The hanging up call process, status: %s", statusmsg);
            break;
        }
        case PJSUA_IP_CHANGE_OP_ACC_REINVITE_CALLS: {
            VSLLogDebug(@"The re-INVITE call process, status: %s", statusmsg);
            break;
        }
        case PJSUA_IP_CHANGE_OP_COMPLETED: {
            VSLLogDebug(@"The ip change process has completed, status: %s", statusmsg);
            [VSLEndpoint sharedEndpoint].ipChangeInProgress = NO;
            break;
        }
        default:
            VSLLogError(@"Unhandled ip change operation encountered, status: %s", statusmsg);
            break;
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
            VSLCall *call = [[VSLEndpoint sharedEndpoint].callManager callWithCallId:call_id];;
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

static void onTransportStateChanged(pjsip_transport *tp, pjsip_transport_state state, const pjsip_transport_state_info *info) {
    VSLLogVerbose(@"Transport state changed to: %@", VSLTransportStateName(state));
    
    if ([[VSLEndpoint sharedEndpoint].endpointConfiguration hasTLSConfiguration] || [[VSLEndpoint sharedEndpoint].endpointConfiguration hasTCPConfiguration]) {
        VSLCallManager *callManager = [VSLEndpoint sharedEndpoint].callManager;
        for (VSLAccount *account in [VSLEndpoint sharedEndpoint].accounts) {
            VSLCall *call = [callManager firstCallForAccount:account];
            if (call != nil && ![VSLEndpoint sharedEndpoint].ipChangeInProgress && state == PJSIP_TP_STATE_CONNECTED) {
                VSLLogInfo(@"There has been a new transport created. Reinivite the calls to keep the call going.");
                [call reinvite];
                VSLLogError(@"State: %u", state);
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
