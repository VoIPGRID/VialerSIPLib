//
//  VSLCall.m
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import "VSLCall.h"

#import <CocoaLumberjack/CocoaLumberjack.h>
#import "NSError+VSLError.h"
#import "NSString+PJString.h"
#import "VSLEndpoint.h"
#import "VSLRingback.h"

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
static NSString * const VSLCallErrorDomain = @"VialerSIPLib.VSLCall";

/**
 The states which the media can have.
 */
typedef NS_ENUM(NSInteger, VSLStatusCodes) {
    VSLStatusCodesBusyHere = PJSIP_SC_BUSY_HERE,

};

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
@property (strong, nonatomic) VSLAccount *account;
@end

@implementation VSLCall

#pragma mark - Life Cycle
+ (instancetype)callNumber:(NSString *)number withAccount:(VSLAccount *)account error:(NSError * _Nullable __autoreleasing *)error {
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
            *error = [NSError VSLUnderlyingError:nil
               localizedDescriptionKey:NSLocalizedString(@"Could not setup call", nil)
           localizedFailureReasonError:[NSString stringWithFormat:NSLocalizedString(@"PJSIP status code: %d", nil), status]
                           errorDomain:VSLCallErrorDomain
                             errorCode:VSLCallErrorCannotCreateCall];
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
            self.incoming = NO;
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
            [self.account removeCall:self];
        } break;
    }
}

- (VSLAccount *)account {
    return [[VSLEndpoint sharedEndpoint] lookupAccount:self.accountId];
}

- (VSLRingback *)ringback {
    if (!_ringback) {
        _ringback = [[VSLRingback alloc] init];
    }
    return _ringback;
}

- (void)updateCallInfo:(pjsua_call_info)callInfo {
    self.callState = (VSLCallState)callInfo.state;
    self.callStateText = [NSString stringWithPJString:callInfo.state_text];
    self.lastStatus = callInfo.last_status;
    self.lastStatusText = [NSString stringWithPJString:callInfo.last_status_text];
    self.localURI = [NSString stringWithPJString:callInfo.local_info];
    self.remoteURI = [NSString stringWithPJString:callInfo.remote_info];
}

- (BOOL)hangup:(NSError * _Nullable __autoreleasing *)error {
    pj_status_t status;

    if (self.callId != PJSUA_INVALID_ID) {
        if (self.callState == VSLCallStateIncoming) {
            status = pjsua_call_hangup((int)self.callId, VSLStatusCodesBusyHere, NULL, NULL);
            if (status != PJ_SUCCESS) {
                if (error != NULL) {
                    *error = [NSError VSLUnderlyingError:nil
                                 localizedDescriptionKey:NSLocalizedString(@"Could not hangup call", nil)
                             localizedFailureReasonError:[NSString stringWithFormat:NSLocalizedString(@"PJSIP status code: %d", nil), status]
                                             errorDomain:VSLCallErrorDomain
                                               errorCode:VSLCallErrorCannotHangupCall];
                }
                return NO;
            }
        } else if (self.callState != VSLCallStateDisconnected) {
            status = pjsua_call_hangup((int)self.callId, 0, NULL, NULL);
            if (status != PJ_SUCCESS) {
                if (error != NULL) {
                    *error = [NSError VSLUnderlyingError:nil
                                 localizedDescriptionKey:NSLocalizedString(@"Could not hangup call", nil)
                             localizedFailureReasonError:[NSString stringWithFormat:NSLocalizedString(@"PJSIP status code: %d", nil), status]
                                             errorDomain:VSLCallErrorDomain
                                               errorCode:VSLCallErrorCannotHangupCall];
                }
                return NO;
            }
        }
    }
    return YES;
}

- (BOOL)answer:(NSError *__autoreleasing  _Nullable *)error {
    pj_status_t status;

    if (self.callId != PJSUA_INVALID_ID) {
        status = pjsua_call_answer((int)self.callId, PJSIP_SC_OK, NULL, NULL);

        if (status != PJ_SUCCESS) {
            if (error != NULL) {
                *error = [NSError VSLUnderlyingError:nil
                             localizedDescriptionKey:NSLocalizedString(@"Could not answer call", nil)
                         localizedFailureReasonError:[NSString stringWithFormat:NSLocalizedString(@"PJSIP status code: %d", nil), status]
                                         errorDomain:VSLCallErrorDomain
                                           errorCode:VSLCallErrorCannotHangupCall];
            }
            return NO;
        }
        return YES;
    }
    return NO;
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
