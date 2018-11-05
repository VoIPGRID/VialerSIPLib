//
//  CallKitProviderDelegate.m
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//
//

#import "CallKitProviderDelegate.h"

#import "VialerSIPLib.h"
#import "VSLAudioController.h"
#import "VSLEndpoint.h"
#import "VSLLogging.h"

NSString * const CallKitProviderDelegateOutboundCallStartedNotification = @"CallKitProviderDelegateOutboundCallStarted";
NSString * const CallKitProviderDelegateInboundCallAcceptedNotification = @"CallKitProviderDelegateInboundCallAccepted";
NSString * const CallKitProviderDelegateInboundCallRejectedNotification = @"CallKitProviderDelegateInboundCallRejected";

@interface CallKitProviderDelegate()
@property (strong, nonatomic) CXProvider *provider NS_AVAILABLE_IOS(10.0);
@property (weak, nonatomic) VSLCallManager *callManager;
@end

@implementation CallKitProviderDelegate

- (instancetype)initWithCallManager:(VSLCallManager *)callManager {
    if (self = [super init]) {
        self.callManager = callManager;
        
        if (@available(iOS 10.0, *)) {
            self.provider = [[CXProvider alloc] initWithConfiguration:[self providerConfiguration]];
            [self.provider setDelegate:self queue:nil];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(callStateChanged:)
                                                         name:VSLCallStateChangedNotification
                                                       object:nil];
        }
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VSLCallStateChangedNotification object:nil];
}

- (CXProviderConfiguration *)providerConfiguration NS_AVAILABLE_IOS(10.0){
    if (@available(iOS 10.0, *)) {
        NSString *appname = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
        CXProviderConfiguration *providerConfiguration = [[CXProviderConfiguration alloc]
                                                          initWithLocalizedName:NSLocalizedString(appname, nil)];
        
        providerConfiguration.maximumCallGroups = 2;
        providerConfiguration.maximumCallsPerCallGroup = 1;
        providerConfiguration.supportsVideo = ![VSLEndpoint sharedEndpoint].endpointConfiguration.disableVideoSupport;
        
        NSString *ringtoneFileName = [[NSBundle mainBundle] pathForResource:@"ringtone" ofType:@"wav"];
        if (ringtoneFileName) {
            providerConfiguration.ringtoneSound = @"ringtone.wav";
        }
        
        providerConfiguration.supportedHandleTypes = [NSSet setWithObject:[NSNumber numberWithInt:CXHandleTypePhoneNumber]];
        
        return providerConfiguration;
    }
    return nil;
}

/**
 * This causes CallKit to show the "native" call screen.
 */
- (void)reportIncomingCall:(VSLCall *)call {
    if (@available(iOS 10.0, *)) {
        CXCallUpdate *update = [[CXCallUpdate alloc] init];
        update.localizedCallerName = call.callerName;
        
        NSString * handleValue = @"";
        if ([update.localizedCallerName length] == 0) { // Doing this to not let the caller contact name override the platform's one
            handleValue = call.callerNumber;
        }
        CXHandle *handle = [[CXHandle alloc] initWithType:CXHandleTypePhoneNumber value:handleValue];
        update.remoteHandle = handle;
  
        VSLLogVerbose(@"UUID as sent to CallKit provider: %@", call.uuid.UUIDString);
        [self.provider reportNewIncomingCallWithUUID:call.uuid update:update completion:^(NSError * _Nullable error) {
            if (error) {
                VSLLogError(@"Call(%@). CallKit report incoming call error: %@", call.uuid.UUIDString, error);
                NSError *hangupError;
                [call hangup:&hangupError];
                
                if (hangupError){
                    VSLLogError(@"Error hanging up call(%@) after CallKit error:%@", call.uuid.UUIDString, error);
                }
            }
        }];
    }
}

// MARK: - CXProviderDelegate
/**
 * Delegate method called when the user accepts the incoming call from within the
 * "native" CallKit interface.
 */
- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action NS_AVAILABLE_IOS(10.0) {
    __weak VSLCall *call = [self.callManager callWithUUID:action.callUUID];
    if (call) {
        [self.callManager.audioController configureAudioSession];

        [call answerWithCompletion:^(NSError *error) {
            if (error) {
                VSLLogError(@"Error answering call(%@) error:%@", call.uuid.UUIDString, error);
                [action fail];

            } else {
                VSLLogVerbose(@"Answering call %@", call.uuid.UUIDString);
                // Post a notification so the outbound call screen can be shown.
                NSDictionary *notificationInfo = @{VSLNotificationUserInfoCallKey : call};
                [[NSNotificationCenter defaultCenter] postNotificationName:CallKitProviderDelegateInboundCallAcceptedNotification
                                                                    object:self
                                                                  userInfo:notificationInfo];
                [action fulfill];
            }
        }];
    } else {
        VSLLogError(@"Error answering call(%@). No call found", action.callUUID.UUIDString);
        [action fail];
    }
}

/**
 * Delegate method called when the user declines the incoming call from within the
 * "native" CallKit interface.
 */
- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action NS_AVAILABLE_IOS(10.0){
    // Find call.
    __weak VSLCall *call = [self.callManager callWithUUID:action.callUUID];
    if (!call) {
        VSLLogInfo(@"Error hanging up call(%@). No call found", action.callUUID.UUIDString);
        [action fulfill];
        return;
    }

    // Decline if incoming, otherwise hangup.
    NSError *error;
    if (call.callState == VSLCallStateIncoming) {
        VSLLogInfo(@"Rejected incoming call, post info so that app can catch.");
        [call decline:&error];
        [[NSNotificationCenter defaultCenter] postNotificationName:CallKitProviderDelegateInboundCallRejectedNotification object:self userInfo:nil];
    } else {
        [call hangup:&error];
    }

    // Check if there was an error hanging up.
    if (error) {
        VSLLogInfo(@"Error hanging up call(%@) error:%@", call.uuid.UUIDString, error);
        [action fail];
    } else {
        VSLLogVerbose(@"Ending call %@", call.uuid.UUIDString);
        [action fulfill];
    }
}

/**
 * Delegate method called when CallKit approves the apps request to start an outbound call.
 */
- (void)provider:(CXProvider *)provider performStartCallAction:(CXStartCallAction *)action NS_AVAILABLE_IOS(10.0) {
    __weak VSLCall *call = [self.callManager callWithUUID:action.callUUID];
    [self.callManager.audioController configureAudioSession];

    [call startWithCompletion:^(NSError *error) {
        if (error) {
            VSLLogError(@"Error starting call(%@) error: %@", call.uuid.UUIDString, error);
            [action fail];
        } else {
            VSLLogInfo(@"Call %@ started", call.uuid.UUIDString);

            // Post a notification so the outbound call screen can be shown.
            NSDictionary *notificationInfo = @{VSLNotificationUserInfoCallKey : call};
            [[NSNotificationCenter defaultCenter] postNotificationName:CallKitProviderDelegateOutboundCallStartedNotification
                                                                object:self
                                                              userInfo:notificationInfo];
            [action fulfill];
        }
    }];
}

- (void)provider:(CXProvider *)provider performSetMutedCallAction:(CXSetMutedCallAction *)action NS_AVAILABLE_IOS(10.0) {
    __weak VSLCall *call = [self.callManager callWithUUID:action.callUUID];
    if (!call) {
        [action fail];
        return;
    }

    NSError *muteError;
    [call toggleMute:&muteError];
    if (muteError) {
        VSLLogError(@"Could not mute call(%@). Error: %@", call.uuid.UUIDString, muteError);
        [action fail];
    } else {
        [action fulfill];
    }
}

- (void)provider:(CXProvider *)provider performSetHeldCallAction:(CXSetHeldCallAction *)action NS_AVAILABLE_IOS(10.0) {
    __weak VSLCall *call = [self.callManager callWithUUID:action.callUUID];
    if (!call) {
        [action fail];
        return;
    }
    NSError *holdError;
    [call toggleHold:&holdError];
    if (holdError) {
        VSLLogError(@"Could not hold call(%@). Error: %@", call.uuid.UUIDString, holdError);
        [action fail];
    } else {
        call.onHold ? [self.callManager.audioController deactivateAudioSession] : [self.callManager.audioController activateAudioSession];
        [action fulfill];
    }
}

- (void)provider:(CXProvider *)provider performPlayDTMFCallAction:(CXPlayDTMFCallAction *)action NS_AVAILABLE_IOS(10.0) {
    __weak VSLCall *call = [self.callManager callWithUUID:action.callUUID];
    if (!call) {
        [action fail];
        return;
    }
    NSError *dtmfError;
    [call sendDTMF:action.digits error:&dtmfError];
    if (dtmfError) {
        VSLLogError(@"Call(%@). Could not send DTMF. Error %@", call.uuid.UUIDString, dtmfError);
        [action fail];
    } else {
        [action fulfill];
    }
}

- (void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession NS_AVAILABLE_IOS(10.0) {
    [self.callManager.audioController activateAudioSession];
}

- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession NS_AVAILABLE_IOS(10.0) {
    [self.callManager.audioController deactivateAudioSession];
}

- (void)providerDidReset:(CXProvider *)provider NS_AVAILABLE_IOS(10.0) {
    VSLLogDebug(@"Provider reset: end all calls");
    [self.callManager endAllCalls];
}

- (void)callStateChanged:(NSNotification *)notification {
    __weak VSLCall *call = [[notification userInfo] objectForKey:VSLNotificationUserInfoCallKey];
    switch (call.callState) {
        case VSLCallStateNull:
            break;

        case VSLCallStateCalling:
            if (!call.isIncoming) {
                VSLLogDebug(@"Outgoing call, in CALLING state, with UUID: %@", call.uuid);
                if (@available(iOS 10.0, *)) {
                    [self.provider reportOutgoingCallWithUUID:call.uuid
                                      startedConnectingAtDate:[NSDate date]];
                }
            }
            break;

        case VSLCallStateIncoming:
            break;

        case VSLCallStateEarly:
            if (!call.isIncoming) {
                VSLLogDebug(@"Outgoing call, in EARLY state, with UUID: %@", call.uuid);
                if (@available(iOS 10.0, *)) {
                    [self.provider reportOutgoingCallWithUUID:call.uuid
                                      startedConnectingAtDate:[NSDate date]];
                }
            }
            break;
        case VSLCallStateConnecting:
            if (!call.isIncoming) {
                VSLLogDebug(@"Outgoing call, in CONNECTING state, with UUID: %@", call.uuid);
                if (@available(iOS 10.0, *)) {
                    [self.provider reportOutgoingCallWithUUID:call.uuid
                                      startedConnectingAtDate:[NSDate date]];
                }
            }
            break;

        case VSLCallStateConfirmed:
            if (!call.isIncoming) {
                VSLLogDebug(@"Outgoing call, in CONFIRMED state, with UUID: %@", call.uuid);
                if (@available(iOS 10.0, *)) {
                    [self.provider reportOutgoingCallWithUUID:call.uuid
                                              connectedAtDate:[NSDate date]];
                }
            }
            break;

        case VSLCallStateDisconnected:
            if (!call.connected) {
                VSLLogDebug(@"Call never connected, in DISCONNECTED state, with UUID: %@", call.uuid);
                
                if (@available(iOS 10.0, *)) {
                    [self.provider reportOutgoingCallWithUUID:call.uuid
                                              connectedAtDate:[NSDate date]];
                    [self.provider reportCallWithUUID:call.uuid
                                          endedAtDate:[NSDate date]
                                               reason:CXCallEndedReasonUnanswered];
                }
            } else if (!call.userDidHangUp) {
                VSLLogDebug(@"Call remotly ended, in DISCONNECTED state, with UUID: %@", call.uuid);
                if (@available(iOS 10.0, *)) {
                    [self.provider reportCallWithUUID:call.uuid
                                          endedAtDate:[NSDate date]
                                               reason:CXCallEndedReasonRemoteEnded];
                }
            }
            break;
    }
}

@end
