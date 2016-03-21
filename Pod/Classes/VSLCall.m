//
//  VSLCall.m
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import "VSLCall.h"

#import <AVFoundation/AVFoundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "NSError+VSLError.h"
#import "NSString+PJString.h"
#import "VSLEndpoint.h"
#import "VSLRingback.h"

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
static NSString * const VSLCallErrorDomain = @"VialerSIPLib.VSLCall";

/**
 *  The sip status codes.
 */
typedef NS_ENUM(NSInteger, VSLStatusCodes) {
    /**
     *  Busy here.
     */
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
@property (readwrite, nonatomic) NSString *callerName;
@property (readwrite, nonatomic) NSString *callerNumber;
@property (readwrite, nonatomic) NSInteger callId;
@property (readwrite, nonatomic) NSInteger accountId;
@property (strong, nonatomic) VSLRingback *ringback;
@property (readwrite, nonatomic) BOOL incoming;
@property (strong, nonatomic) VSLAccount *account;
@property (readwrite, nonatomic) BOOL muted;
@property (readwrite, nonatomic) BOOL speaker;
@property (readwrite, nonatomic) BOOL onHold;
@property (strong, nonatomic) NSString *currentAudioSessionCategory;
@end

@implementation VSLCall

#pragma mark - Life Cycle

+ (instancetype)callNumber:(NSString *)number withAccount:(VSLAccount *)account error:(NSError * _Nullable __autoreleasing *)error {
    NSError *audioSessionCategoryError;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&audioSessionCategoryError];

    if (audioSessionCategoryError) {
        DDLogError(@"Error setting the correct AVAudioSession category");
        if (error != NULL) {
            *error = [NSError VSLUnderlyingError:nil
                         localizedDescriptionKey:NSLocalizedString(@"Error setting the correct AVAudioSession category", nil)
                     localizedFailureReasonError:NSLocalizedString(@"Error setting the correct AVAudioSession category", nil)
                                     errorDomain:VSLCallErrorDomain
                                       errorCode:VSLCallErrorCannotCreateCall];
        }
        return nil;
    }
    pj_str_t sipUri = [number sipUriWithDomain:account.accountConfiguration.sipDomain];

    // Create call settings.
    pjsua_call_setting callSetting;
    pjsua_call_setting_default(&callSetting);
    callSetting.aud_cnt = 1;

    pjsua_call_id callIdentifier;

    pj_status_t status = pjsua_call_make_call((int)account.accountId, &sipUri, &callSetting, NULL, NULL, &callIdentifier);

    if (status != PJ_SUCCESS) {
        DDLogError(@"Error creating call");
        if (error != NULL) {
            *error = [NSError VSLUnderlyingError:nil
               localizedDescriptionKey:NSLocalizedString(@"Could not setup call", nil)
           localizedFailureReasonError:[NSString stringWithFormat:NSLocalizedString(@"PJSIP status code: %d", nil), status]
                           errorDomain:VSLCallErrorDomain
                             errorCode:VSLCallErrorCannotCreateCall];
        }
        return nil;
    }
    DDLogVerbose(@"Created call");
    VSLCall *call = [VSLCall callWithId:callIdentifier andAccountId:account.accountId];
    [account addCall:call];
    return call;
}

+ (instancetype)callWithId:(NSInteger)callId andAccountId:(NSInteger)accountId {
    DDLogVerbose(@"Creating call");

    VSLCall *call = [[VSLCall alloc] initWithCallId:callId accountId:accountId];
    return call;
}

- (instancetype)initWithCallId:(NSUInteger)callId accountId:(NSInteger)accountId {
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

#pragma mark - Properties

- (void)setCallState:(VSLCallState)callState {
    if (_callState != callState) {
        [self willChangeValueForKey:@"callState"];
        _callState = callState;
        [self didChangeValueForKey:@"callState"];

        switch (_callState) {
            case VSLCallStateNull: {

            } break;
            case VSLCallStateIncoming: {

            } break;

            case VSLCallStateCalling: {

            } break;

            case VSLCallEarlyState: {
                [self.ringback start];
            } break;

            case VSLCallStateConnecting: {

            } break;

            case VSLCallStateConfirmed: {
                [self.ringback stop];
                // Register for the audio interruption notification to be able to restore the sip audio session after an interruption (incoming call/alarm....).
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioInterruption:) name:AVAudioSessionInterruptionNotification object:nil];
            } break;

            case VSLCallStateDisconnected: {
                [self.ringback stop];
                [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionInterruptionNotification object:nil];
                [self.account removeCall:self];
            } break;
        }
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

#pragma mark - Callback methods

- (void)updateCallInfo:(pjsua_call_info)callInfo {
    self.callState = (VSLCallState)callInfo.state;
    self.callStateText = [NSString stringWithPJString:callInfo.state_text];
    self.lastStatus = callInfo.last_status;
    self.lastStatusText = [NSString stringWithPJString:callInfo.last_status_text];
    self.localURI = [NSString stringWithPJString:callInfo.local_info];
    self.remoteURI = [NSString stringWithPJString:callInfo.remote_info];
    NSDictionary *callerInfo = [self getCallerInfoFromRemoteUri:self.remoteURI];
    self.callerName = callerInfo[@"caller_name"];
    self.callerNumber = callerInfo[@"caller_number"];

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
        [self.ringback stop];
        pjsua_conf_connect(callInfo.conf_slot, 0);
        pjsua_conf_connect(0, callInfo.conf_slot);
    }

    [self updateCallInfo:callInfo];
}

#pragma mark - User actions

- (BOOL)answer:(NSError *__autoreleasing  _Nullable *)error {
    pj_status_t status;

    if (self.callId != PJSUA_INVALID_ID) {
        NSError *audioSessionCategoryError;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&audioSessionCategoryError];
        if (audioSessionCategoryError) {
            DDLogError(@"Error setting the correct AVAudioSession category");
            if (error != NULL) {
                *error = [NSError VSLUnderlyingError:nil
                             localizedDescriptionKey:NSLocalizedString(@"Error setting the correct AVAudioSession category", nil)
                         localizedFailureReasonError:NSLocalizedString(@"Error setting the correct AVAudioSession category", nil)
                                         errorDomain:VSLCallErrorDomain
                                           errorCode:VSLCallErrorCannotCreateCall];
            }
            return NO;
        }

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

- (BOOL)decline:(NSError *__autoreleasing  _Nullable *)error {
    pj_status_t status = pjsua_call_answer((int)self.callId, VSLStatusCodesBusyHere, NULL, NULL);
    if (status != PJ_SUCCESS) {
        if (error != NULL) {
            *error = [NSError VSLUnderlyingError:nil
                         localizedDescriptionKey:NSLocalizedString(@"Could not decline call", nil)
                     localizedFailureReasonError:[NSString stringWithFormat:NSLocalizedString(@"PJSIP status code: %d", nil), status]
                                     errorDomain:VSLCallErrorDomain
                                       errorCode:VSLCallErrorCannotDeclineCall];
        }
        return NO;
    }
    return YES;
}

- (BOOL)hangup:(NSError * _Nullable __autoreleasing *)error {
    if (self.callId != PJSUA_INVALID_ID) {
        if (self.callState != VSLCallStateDisconnected) {
            pj_status_t status = pjsua_call_hangup((int)self.callId, 0, NULL, NULL);
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

- (BOOL)toggleMute:(NSError *__autoreleasing  _Nullable *)error {
    if (self.callState != VSLCallStateConfirmed) {
        return YES;
    }

    pjsua_call_info callInfo;
    pjsua_call_get_info((pjsua_call_id)self.callId, &callInfo);

    pj_status_t status;
    if (!self.muted) {
        status = pjsua_conf_disconnect(0, callInfo.conf_slot);
    } else {
        status = pjsua_conf_connect(0, callInfo.conf_slot);
    }

    if (status == PJ_SUCCESS) {
        self.muted = !self.muted;
        DDLogVerbose(self.muted ? @"Microphone muted": @"Microphone unmuted");
    } else {
        if (error != NULL) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey:NSLocalizedString(@"Could not toggle mute call", nil),
                                       NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:NSLocalizedString(@"PJSIP status code: %d", status)]
                                       };
            *error = [NSError errorWithDomain:VSLCallErrorDomain code:VSLCallErrorCannotToggleMute userInfo:userInfo];
        }
        return NO;
        DDLogError(@"Error toggle muting microphone in call %@", self);
    }
    return YES;
}

- (void)toggleSpeaker {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    if (!self.speaker) {
        [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
        self.speaker = YES;
    } else {
        [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
        self.speaker = NO;
    }
    DDLogVerbose(self.speaker ? @"Speaker modus activated": @"Speaker modus deactivated");
}

- (BOOL)toggleHold:(NSError *__autoreleasing  _Nullable *)error {
    if (self.callState != VSLCallStateConfirmed) {
        return YES;
    }
    pj_status_t status;

    if (self.onHold) {
        status = pjsua_call_reinvite((pjsua_call_id)self.callId, PJ_TRUE, NULL);
    } else {
        status = pjsua_call_set_hold((pjsua_call_id)self.callId, NULL);
    }

    if (status == PJ_SUCCESS) {
        self.onHold = !self.onHold;
        DDLogVerbose(self.onHold ? @"Call is on hold": @"On hold state ended");
    } else {
        if (error != NULL) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey:NSLocalizedString(@"Could not toggle onhold call", nil),
                                       NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:NSLocalizedString(@"PJSIP status code: %d", status)]
                                       };
            *error = [NSError errorWithDomain:VSLCallErrorDomain code:VSLCallErrorCannotToggleHold userInfo:userInfo];
        }
        return NO;
        DDLogError(@"Error toggle muting microphone in call %@", self);
    }
    return YES;
}

- (BOOL)sendDTMF:(NSString *)character error:(NSError *__autoreleasing  _Nullable *)error {
    // Return if the call is not confirmed or when the call is on hold.
    if (self.callState != VSLCallStateConfirmed || self.onHold) {
        return YES;
    }

    pj_status_t status;
    pj_str_t digits = [character pjString];

    // Try sending DTMF digits to remote using RFC 2833 payload format first.
    status = pjsua_call_dial_dtmf((pjsua_call_id)self.callId, &digits);

    if (status == PJ_SUCCESS) {
        DDLogVerbose(@"Succesfull send character: %@ for DTMF for call %@", character, self);
    } else {
        // The RFC 2833 payload format did not work.
        const pj_str_t kSIPINFO = pj_str("INFO");

        for (NSUInteger i = 0; i < [character length]; ++i) {
            pjsua_msg_data messageData;
            pjsua_msg_data_init(&messageData);
            messageData.content_type = pj_str("application/dtmf-relay");

            NSString *messageBody = [NSString stringWithFormat:@"Signal=%C\r\nDuration=300", [character characterAtIndex:i]];
            messageData.msg_body = [messageBody pjString];

            status = pjsua_call_send_request((pjsua_call_id)self.callId, &kSIPINFO, &messageData);
            if (status == PJ_SUCCESS) {
                DDLogVerbose(@"Succesfull send character: %@ for DTMF for call %@", character, self);
            } else {
                if (error != NULL) {
                    NSDictionary *userInfo = @{NSLocalizedDescriptionKey:NSLocalizedString(@"Could not send DTMF", nil),
                                               NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:NSLocalizedString(@"PJSIP status code: %d", status)]
                                               };
                    *error = [NSError errorWithDomain:VSLCallErrorDomain code:VSLCallErrorCannotSendDTMF userInfo:userInfo];
                }
                return NO;
                DDLogError(@"Error error sending DTMF for call %@", self);
            }
        }
    }
    return YES;
}

/**
 *  Function called on AVAudioSessionInterruptionNotification
 *
 *  The class registers for AVAudioSessionInterruptionNotification to be able to regain
 *  audio after it has been interrupted by another call or other audio event.
 *
 *  @param notification The notification which lead to this function being invoked over GCD.
 */
- (void)audioInterruption:(NSNotification *)notification {
    if ([notification.name isEqualToString:AVAudioSessionInterruptionNotification]) {

        NSInteger avInteruptionType = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
        if (avInteruptionType == AVAudioSessionInterruptionTypeBegan) {
            [self toggleHold:nil];
            pjsua_set_no_snd_dev();
        } else if (avInteruptionType == AVAudioSessionInterruptionTypeEnded) {
            [self toggleHold:nil];
            // Resume audio
            int capture_dev, playback_dev;
            pjsua_get_snd_dev(&capture_dev, &playback_dev);
            pjsua_set_snd_dev(capture_dev, playback_dev);
        }
    }
}

#pragma mark - KVO override

+ (BOOL)automaticallyNotifiesObserversOfCallState {
    return NO;
}

#pragma mark - helper function

/**
 *  Get the caller_name and caller_number from a string
 *
 *  @param string the input string formatter like "name" <sip:42@sip.nl>
 *
 *  @return NSDictionary output like @{"caller_name: name, "caller_number": 42}.
 */
- (NSDictionary *)getCallerInfoFromRemoteUri:(NSString *)string {
    NSString *callerName = @"";
    NSString *callerNumber = @"";
    NSString *callerHost;
    NSString *destination;
    NSRange delimterRange;
    NSRange atSignRange;
    NSRange semiColonRange;
    // Create a character set which will be trimmed from the string.
    NSMutableCharacterSet *charactersToTrim = [[NSCharacterSet whitespaceCharacterSet] mutableCopy];

    if ([[NSPredicate predicateWithFormat:@"SELF MATCHES '.+\\\\s\\\\(.+\\\\)'"] evaluateWithObject:string]) {
        /**
         * This matches the remote_uri for a format of: "destination (display_name)
         */

        delimterRange = [string rangeOfString:@" (" options:NSBackwardsSearch];

        // Create a character set which will be trimmed from the string.
        // All in-line whitespace and double quotes.
        [charactersToTrim addCharactersInString:@"\"()"];

        callerName = [[string substringFromIndex:delimterRange.location] stringByTrimmingCharactersInSet:charactersToTrim];

        destination = [string substringToIndex:delimterRange.location];

        // Get the last part of the uri starting from @
        atSignRange = [destination rangeOfString:@"@" options:NSBackwardsSearch];
        callerHost = [destination substringToIndex: atSignRange.location];

        // Get the telephone part starting from the :
        semiColonRange = [callerHost rangeOfString:@":" options:NSBackwardsSearch];
        callerNumber = [callerHost substringFromIndex:semiColonRange.location + 1];
    } else if ([[NSPredicate predicateWithFormat:@"SELF MATCHES '.+\\\\s<.+>'"] evaluateWithObject:string]) {
        /**
         *  This matches the remote_uri format of: "display_name" <destination_address>
         */

        delimterRange = [string rangeOfString:@" <" options:NSBackwardsSearch];

        // All in-line whitespace and double quotes.
        [charactersToTrim addCharactersInString:@"\""];

        // Get the caller_name from to where the first < is
        // and also trimming the characters defined in charactersToTrim.
        callerName = [[string substringToIndex:delimterRange.location] stringByTrimmingCharactersInSet:charactersToTrim];

        // Get the second part of the uri starting from the <
        NSRange destinationRange = NSMakeRange(delimterRange.location + 2,
                                               ([string length] - (delimterRange.location + 2) - 1));
        destination = [string substringWithRange: destinationRange];

        // Get the last part of the uri starting from @
        atSignRange = [destination rangeOfString:@"@" options:NSBackwardsSearch];
        callerHost = [destination substringToIndex: atSignRange.location];

        // Get the telephone part starting from the :
        semiColonRange = [callerHost rangeOfString:@":" options:NSBackwardsSearch];
        callerNumber = [callerHost substringFromIndex:semiColonRange.location + 1];
    } else if ([[NSPredicate predicateWithFormat:@"SELF MATCHES '<.+\\\\>'"] evaluateWithObject:string]) {
        /**
         * This matches the remote_uri format of: <sip:42@test.nl>
         */

        // Get the second part of the uri starting from the <
        NSRange destinationRange = NSMakeRange(1,
                                               ([string length] - 2));
        destination = [string substringWithRange: destinationRange];

        // Get the last part of the uri starting from @
        atSignRange = [destination rangeOfString:@"@" options:NSBackwardsSearch];
        callerHost = [destination substringToIndex: atSignRange.location];

        // Get the telephone part starting from the :
        semiColonRange = [callerHost rangeOfString:@":" options:NSBackwardsSearch];
        callerNumber = [callerHost substringFromIndex:semiColonRange.location + 1];
    } else {
        /**
         * This matches the remote_uri format of: sip:42@test.nl
         */

        // Get the last part of the uri starting from @
        atSignRange = [string rangeOfString:@"@" options:NSBackwardsSearch];
        callerHost = [string substringToIndex: atSignRange.location];

        // Get the telephone part starting from the :
        semiColonRange = [callerHost rangeOfString:@":" options:NSBackwardsSearch];
        callerNumber = [callerHost substringFromIndex:semiColonRange.location + 1];
    }

    return @{
             @"caller_name": callerName,
             @"caller_number": callerNumber,
             };
}

@end
