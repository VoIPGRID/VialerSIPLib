//
//  VSLCall.m
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import "VSLCall.h"

#import <CocoaLumberjack/CocoaLumberjack.h>
#import "NSString+PJString.h"
#import "VSLRingback.h"

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
static NSString * const VSLCallErrorDomain = @"VialerSIPLib.VSLCall";

@interface VSLCall()
@property (readwrite, nonatomic) VSLCallState callState;
@property (readwrite, nonatomic) NSString *callStateText;
@property (readwrite, nonatomic) NSInteger lastStatus;
@property (readwrite, nonatomic) NSString *lastStatusText;
@property (readwrite, nonatomic) VSLMediaState mediaState;
@property (readwrite, nonatomic) NSString *localURI;
@property (readwrite, nonatomic) NSString *remoteURI;
@property (readwrite, nonatomic) NSInteger callId;
@property (readwrite, nonatomic) NSInteger accountId;
@property (strong, nonatomic) VSLRingback *ringback;
@property (readwrite, nonatomic) BOOL incoming;
@end

@implementation VSLCall

#pragma mark - Life Cycle
+ (instancetype)callNumber:(NSString *)number withAccount:(VSLAccount *)account error:(NSError **)error {
    pj_str_t sipUri = [number sipUriWithDomain:account.accountConfiguration.sipDomain];

    // Create call settings.
    pjsua_call_setting callSetting;
    pjsua_call_setting_default(&callSetting);
    callSetting.aud_cnt = 1;

    pjsua_call_id callIdentifier;

    pj_status_t status = pjsua_call_make_call((int)account.accountId, &sipUri, &callSetting, NULL, NULL, &callIdentifier);

    if (status != PJ_SUCCESS) {
        DDLogInfo(@"Error creating call");
        if (error != NULL) {
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey: NSLocalizedString(@"Could not setup call", nil),
                                       NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"PJSIP status code: %d", nil), status],
                                       };
            *error = [NSError errorWithDomain:VSLCallErrorDomain code:VSLCallErrorCannotCreateCall userInfo:userInfo];
        }
        return nil;
    }
    DDLogInfo(@"Created call");
    VSLCall *call = [VSLCall callWithId:callIdentifier andAccountId:account.accountId];
    [account addCall:call];
    return call;
}

+ (instancetype)callWithId:(NSInteger)callId andAccountId:(NSInteger)accountId {
    DDLogVerbose(@"Creating call");

    VSLCall *call = [[VSLCall alloc] initWithCallId:callId accountId:accountId];
    return call;
}

-(instancetype)initWithCallId:(NSUInteger)callId accountId:(NSInteger)accountId {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.callId = callId;
    self.accountId = accountId;

    pjsua_call_info callInfo;
    pj_status_t status = pjsua_call_get_info((pjsua_call_id)callId, &callInfo);
    if (status == PJ_SUCCESS) {
        [self updateCallInfo:callInfo];
        if (callInfo.state == VSLCallStateIncoming) {
            self.incoming = YES;
        } else {
            self.incoming = YES;
        }
    }
    return self;
}

#pragma mark - properties

- (void)setCallState:(VSLCallState)callState {
    _callState = callState;

    switch (_callState) {
        case VSLCallStateNull: {

        } break;
        case VSLCallStateIncoming: {

        } break;

        case VSLCallStateCalling: {
            [self.ringback start];
        } break;

        case VSLCallEarlyState: {
            [self.ringback start];
        } break;

        case VSLCallStateConnecting: {

        } break;

        case VSLCallStateConfirmed: {
            [self.ringback stop];
        } break;

        case VSLCallStateDisconnected: {
            [self.ringback stop];
        } break;
    }
}

- (void)updateCallInfo:(pjsua_call_info)callInfo {
    self.callState = (VSLCallState)callInfo.state;
    self.callStateText = [NSString stringWithPJString:callInfo.state_text];
    self.lastStatus = callInfo.last_status;
    self.lastStatusText = [NSString stringWithPJString:callInfo.last_status_text];
    self.localURI = [NSString stringWithPJString:callInfo.local_info];
    self.remoteURI = [NSString stringWithPJString:callInfo.remote_info];
}

- (VSLRingback *)ringback {
    if (!_ringback) {
        _ringback = [[VSLRingback alloc] init];
    }
    return _ringback;
}

- (BOOL)hangup:(NSError **)error {
    pj_status_t status;

    if (self.callId != PJSUA_INVALID_ID && self.callState != VSLCallStateDisconnected) {
        status = pjsua_call_hangup((int)self.callId, 0, NULL, NULL);
        if (status != PJ_SUCCESS) {
            if (error != NULL) {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: NSLocalizedString(@"Could not hangup call", nil),
                                           NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"PJSIP status code: %d", nil), status],
                                           };
                *error = [NSError errorWithDomain:VSLCallErrorDomain code:VSLCallErrorCannotHangupCall userInfo:userInfo];
            }
            return NO;
        }
    }
    return YES;
}

- (void)callStateChanged:(pjsua_call_info)callInfo {
    DDLogVerbose(@"Updated callState: %d", callInfo.state);
    [self updateCallInfo:callInfo];
    self.callState = (VSLCallState)callInfo.state;
}

- (void)mediaStateChanged:(pjsua_call_info)callInfo  {
    DDLogVerbose(@"Updated mediaState: %d", callInfo.state);
    pjsua_call_media_status mediaState = callInfo.media_status;
    self.mediaState = (VSLMediaState)mediaState;

    if (_mediaState == PJSUA_CALL_MEDIA_ACTIVE || _mediaState == PJSUA_CALL_MEDIA_REMOTE_HOLD) {
        pjsua_conf_connect(callInfo.conf_slot, 0);
        pjsua_conf_connect(0, callInfo.conf_slot);
    }

    [self updateCallInfo:callInfo];
}

@end
