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

    if (self.endpointConfiguration.codecConfiguration != NULL) {
        [self updateAudioCodecs];
        [self updateVideoCodecs];
    } else {
        [self updateCodecs];
    }

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
            VSLLogError(@"Error registering thread at PJSUA");
        }
    }

    if (self.pjPool != NULL) {
        pj_pool_release(self.pjPool);
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

-(BOOL)updateAudioCodecs {
    if (self.state != VSLEndpointStarted) {
        return NO;
    }

    const unsigned audioCodecInfoSize = 64;
    pjsua_codec_info audioCodecInfo[audioCodecInfoSize];
    unsigned audioCodecCount = audioCodecInfoSize;
    pj_status_t status = pjsua_enum_codecs(audioCodecInfo, &audioCodecCount);
    if (status != PJ_SUCCESS) {
        VSLLogError(@"Error getting list of audio codecs");
        return NO;
    }

    for (NSUInteger i = 0; i < audioCodecCount; i++) {
        NSString *codecIdentifier = [NSString stringWithPJString:audioCodecInfo[i].codec_id];
        pj_uint8_t priority = [self priorityForAudioCodec:codecIdentifier];
        status = pjsua_codec_set_priority(&audioCodecInfo[i].codec_id, priority);
        if (status != PJ_SUCCESS) {
            VSLLogError(@"Error setting codec priority to the correct value");
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

-(BOOL)updateVideoCodecs {
    if (self.state != VSLEndpointStarted) {
        return NO;
    }

    const unsigned videoCodecInfoSize = 64;
    pjsua_codec_info videoCodecInfo[videoCodecInfoSize];
    unsigned videoCodecCount = videoCodecInfoSize;
    pj_status_t videoStatus = pjsua_vid_enum_codecs(videoCodecInfo, &videoCodecCount);
    if (videoStatus != PJ_SUCCESS) {
        VSLLogError(@"Error getting list of video codecs");
        return NO;
    } else {
        for (NSUInteger i = 0; i < videoCodecCount; i++) {
            NSString *codecIdentifier = [NSString stringWithPJString:videoCodecInfo[i].codec_id];
            pj_uint8_t priority = [self priorityForVideoCodec:codecIdentifier];
            
            videoStatus = pjsua_vid_codec_set_priority(&videoCodecInfo[i].codec_id, priority);

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

                if (videoStatus != PJ_SUCCESS) {
                    DDLogError(@"Error setting video codec priority to the correct value");
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
    NSString *pattern = @"(?:.*)/([A-Z]+)/(?:.*)SIP/2.0 ([4|5]{1}[0-9]{2}) ([A-Za-z ]+)?(?:.*)Call-ID: ([A-Za-z0-9@.]+)?";
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

static void onCallState(pjsua_call_id callId, pjsip_event *event) {
    VSLLogVerbose(@"onCallState");
    pjsua_call_info callInfo;
    pjsua_call_get_info(callId, &callInfo);

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

static void onCallMediaState(pjsua_call_id call_id) {
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

static void onRegStarted2(pjsua_acc_id acc_id, pjsua_reg_info *info) {
    VSLLogVerbose(@"onRegStarted2");
}

static void onRegState2(pjsua_acc_id acc_id, pjsua_reg_info *info) {
    VSLLogVerbose(@"onRegState2");

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
                        VSLLogInfo(@"Do a update for all calls of account: %d", acc_id);
                        [[[VSLEndpoint sharedEndpoint] callManager] updateActiveCallsForAccount:account];
                        break;
                    case VSLIpChangeConfigurationIpChangeCallsDefault:
                        // Do nothing.
                        break;
                }
            }
        }
    }
}

/* Callback on media events. Adjust renderer window size to original video size */
static void onCallMediaEvent(pjsua_call_id call_id, unsigned med_idx, pjmedia_event *event) {
    #if PJSUA_HAS_VIDEO
        if (event->type == PJMEDIA_EVENT_FMT_CHANGED) {
            char event_name[5];
            VSLLogVerbose(@"Event Media %s", pjmedia_fourcc_name(event->type, event_name));
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

static void onIncomingCall(pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata) {
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
        call = nil;
    } else {
        VSLLogWarning(@"Could not accept incoming call. No account found with ID:%d", acc_id);
    }
}

static void onCallTransferStatus(pjsua_call_id callId, int statusCode, const pj_str_t *statusText, pj_bool_t final, pj_bool_t *continueNotifications) {
    VSLCall *call = [[VSLEndpoint sharedEndpoint].callManager callWithCallId:callId];
    if (call) {
        [call callTransferStatusChangedWithStatusCode:statusCode statusText:[NSString stringWithPJString:*statusText] final:final == 1];
    }
}

- (void)callDealloc:(NSNotification *)notification {
    if (!self.endpointConfiguration.unregisterAfterCall || self.state != VSLEndpointStarted) {
        return;
    }

    for (VSLAccount *account in self.accounts) {
        if (![self.callManager firstActiveCallForAccount:account]) {
            NSArray *calls = [self.callManager callsForAccount:account];
            if (calls.count == 0) {
                NSError *error;
                [account unregisterAccount:&error];
            }
        }
    }
    
    if ([[VSLEndpoint sharedEndpoint].endpointConfiguration hasTCPConfiguration] || [[VSLEndpoint sharedEndpoint].endpointConfiguration hasTLSConfiguration]) {
        // Remove all current transports.
        pjsua_transport_id transportIds[32];
        unsigned count = PJ_ARRAY_SIZE(transportIds);
        
        pj_status_t status = pjsua_enum_transports (transportIds, &count);

        if (status == PJ_SUCCESS && count > 1) {
            for (int i = 1; i < count; i++) {
                pjsua_transport_id tId = transportIds[i];
                pjsua_transport_info info;
                pj_status_t status = pjsua_transport_get_info(tId, &info);
                if (status == PJ_SUCCESS) {
                    VSLLogError(@"SUCCESS: Destoryed transport: %d", i);
                } else {
                    VSLLogError(@"FAILED: Destoryed transport: %d", i);
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
 *  To prevent registration to quickly or to often, we wait for a second before actually sending the registration.
 *  This is needed because switching to or between mobile networks can happen multiple times in a short time.
 *
 *  @param notification The notification which lead to this function being invoked over GCD.
 */
- (void)ipAddressChanged:(NSNotification *)notification {
    pjsua_ip_change_param param;
    pjsua_ip_change_param_default(&param);
    param.restart_lis_delay = 100;
    param.restart_listener = PJ_TRUE;

    pjsua_handle_ip_change(&param);
}

static void onIpChangeProgress(pjsua_ip_change_op op, pj_status_t status, const pjsua_ip_change_op_info *info) {
    VSLLogInfo(@"onIpChangeProgress:");

    [VSLEndpoint sharedEndpoint].ipChangeInProgress = YES;

    switch (op) {
        case PJSUA_IP_CHANGE_OP_RESTART_LIS: {
            VSLLogInfo(@"Restart Listener: %u", status);
            break;
        }
        case PJSUA_IP_CHANGE_OP_ACC_SHUTDOWN_TP: {
            VSLLogInfo(@"Account Shutdown transport: %u", status);
            break;
        }
        case PJSUA_IP_CHANGE_OP_ACC_UPDATE_CONTACT: {
            VSLLogInfo(@"Account update contact: %u", status);
            break;
        }
        case PJSUA_IP_CHANGE_OP_ACC_HANGUP_CALLS: {
            VSLLogInfo(@"Account hangup calls: %u", status);
            break;
        }
        case PJSUA_IP_CHANGE_OP_ACC_REINVITE_CALLS: {
            VSLLogInfo(@"Account reinvite calls: %u", status);
            [VSLEndpoint sharedEndpoint].ipChangeInProgress = NO;
            break;
        }
        default:
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
