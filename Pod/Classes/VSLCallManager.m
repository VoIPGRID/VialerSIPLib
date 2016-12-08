//
//  VSLCallManager.m
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//
//

#import "VSLCallManager.h"

@import CallKit;
#import "Constants.h"
#import <CocoaLumberJack/CocoaLumberjack.h>
#import "VSLAccount.h"
#import "VSLAudioController.h"
#import "VSLCall.h"
#import "VialerSIPLib.h"


@interface VSLCallManager()
@property (strong, nonatomic) NSMutableArray *calls;
@property (strong, nonatomic) VSLAudioController *audioController;
@property (strong, nonatomic) CXCallController *callController;
@end

@implementation VSLCallManager

- (instancetype)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(callStateChanged:)
                                                     name:VSLCallStateChangedNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VSLCallStateChangedNotification object:nil];
}

- (NSMutableArray *)calls {
    if (!_calls) {
        _calls = [[NSMutableArray alloc] init];
    }
    return _calls;
}

- (VSLAudioController *)audioController {
    if (!_audioController) {
        _audioController = [[VSLAudioController alloc] init];
    }
    return _audioController;
}

- (CXCallController *)callController {
    if (!_callController) {
        _callController = [[CXCallController alloc] init];
    }
    return _callController;
}

- (void)startCallToNumber:(NSString *)number forAccount:(VSLAccount *)account completion:(void (^)(VSLCall *call, NSError *error))completion {
    VSLCall *call = [[VSLCall alloc] initOutboundCallWithNumberToCall:number account:account];
    [self addCall:call];

    if ([VialerSIPLib callKitAvailable]) {
        CXHandle *numberHandle = [[CXHandle alloc] initWithType:CXHandleTypePhoneNumber value:call.numberToCall];
        CXAction *startCallAction = [[CXStartCallAction alloc] initWithCallUUID:call.uuid handle:numberHandle];

        [self requestCallKitAction:startCallAction completion:^(NSError *error) {
            if (error) {
                DDLogError(@"Error requesting \"Start Call Transaction\" error: %@", error);
                [self removeCall:call];
                completion(nil, error);
            } else {
                DDLogInfo(@"\"Start Call Transaction\" requested succesfully for Call(%@) with account(%ld)", call.uuid.UUIDString, (long)account.accountId);
                completion(call, nil);
            }
        }];
    } else {
        DDLogVerbose(@"Starting call: %@", call.uuid.UUIDString);
        [self.audioController configureAudioSession];
        [call startWithCompletion:^(NSError *error) {
            if (error) {
                DDLogError(@"Error starting call(%@): %@", call.uuid.UUIDString, error);
                completion(nil, error);
            } else {
                DDLogInfo(@"Call(%@) started", call.uuid.UUIDString);
                [self.audioController activateAudioSession];
                completion(call, nil);
            }
        }];
    }
}

- (void)answerCall:(VSLCall *)call completion:(void (^)(NSError *error))completion {
    if ([VialerSIPLib callKitAvailable]) {
        [call answerWithCompletion:completion];
    } else {
        [self.audioController configureAudioSession];
        [call answerWithCompletion:^(NSError * _Nullable error) {
            if (error) {
                completion(error);
            } else {
                [self.audioController activateAudioSession];
                completion(nil);
            }
        }];
    }
}

- (void)endCall:(VSLCall *)call completion:(void (^)(NSError *error))completion {
    if ([VialerSIPLib callKitAvailable]) {
        CXAction *endCallAction = [[CXEndCallAction alloc] initWithCallUUID:call.uuid];
        [self requestCallKitAction:endCallAction completion:completion];

    } else {
        DDLogVerbose(@"Ending call: %@", call.uuid.UUIDString);
        NSError *hangupError;
        [call hangup:&hangupError];
        if (hangupError) {
            DDLogError(@"Could not hangup call(%@). Error: %@", call.uuid.UUIDString, hangupError);
            completion(hangupError);
        } else {
            DDLogInfo(@"\"End Call Transaction\" requested succesfully for Call(%@)", call.uuid.UUIDString);
            completion(nil);
        }
    }
}

- (void)toggleMuteForCall:(VSLCall *)call completion:(void (^)(NSError *error))completion {
    if ([VialerSIPLib callKitAvailable]) {
        CXAction *toggleMuteAction = [[CXSetMutedCallAction alloc] initWithCallUUID:call.uuid muted:!call.muted];
        [self requestCallKitAction:toggleMuteAction completion:completion];

    } else {
        NSError *muteError;
        [call toggleMute:&muteError];
        if (muteError) {
            DDLogError(@"Could not mute call. Error: %@", muteError);
            completion(muteError);
        } else {
            DDLogInfo(@"\"Mute Call Transaction\" requested succesfully for Call(%@)", call.uuid.UUIDString);
            completion(nil);
        }
    }
}

- (void)toggleHoldForCall:(VSLCall *)call completion:(void (^)(NSError * _Nullable))completion {
    if ([VialerSIPLib callKitAvailable]) {
        CXAction *toggleHoldAction = [[CXSetHeldCallAction alloc] initWithCallUUID:call.uuid onHold:!call.onHold];
        [self requestCallKitAction:toggleHoldAction completion:completion];
    } else {
        NSError *holdError;
        [call toggleHold:&holdError];
        if (holdError) {
            DDLogError(@"Could not hold call (%@). Error: %@", call.uuid.UUIDString, holdError);
            completion(holdError);
        } else {
            DDLogInfo(@"\"Hold Call Transaction\" requested succesfully for Call(%@)", call.uuid.UUIDString);
            completion(nil);
        }
    }

}

- (void)sendDTMFForCall :(VSLCall *)call character:(NSString *)character completion:(void (^)(NSError * _Nullable))completion {
    if([VialerSIPLib callKitAvailable]) {
        CXAction *dtmfAction = [[CXPlayDTMFCallAction alloc] initWithCallUUID:call.uuid digits:character type:CXPlayDTMFCallActionTypeSingleTone];
        [self requestCallKitAction:dtmfAction completion:completion];

    } else {
        NSError *dtmfError;
        [call sendDTMF:character error:&dtmfError];
        if (dtmfError) {
            DDLogError(@"Could not send DTMF. Error: %@", dtmfError);
            completion(dtmfError);
        } else {
            DDLogInfo(@"\"Sent DTMF Transaction\" requested succesfully for Call(%@)", call.uuid.UUIDString);
            completion(nil);
        }
    }
}

- (void)requestCallKitAction:(CXAction *)action completion:(void (^)(NSError *error))completion {
    CXTransaction *transaction = [[CXTransaction alloc] initWithAction:action];
    [self.callController requestTransaction:transaction completion:^(NSError * _Nullable error) {
        if (error) {
            DDLogError(@"Error requesting transaction: %@. Error:%@", transaction, error);
            completion(error);
        } else {
            completion(nil);
        }
    }];
}

- (void)addCall:(VSLCall *)call {
    [self.calls addObject:call];
    DDLogVerbose(@"Call(%@) added. Calls count:%ld",call.uuid.UUIDString, (long)[self.calls count]);

}

- (void)removeCall:(VSLCall *)call {
    [self.calls removeObject:call];
    DDLogVerbose(@"Call(%@) removed. Calls count: %ld",call.uuid.UUIDString, (long)[self.calls count]);
}

- (void)endAllCalls {
    for (VSLCall *call in self.calls) {
        DDLogVerbose(@"Ending call: %@", call.uuid.UUIDString);
        NSError *hangupError;
        [call hangup:&hangupError];
        if (hangupError) {
            DDLogError(@"Could not hangup call(%@). Error: %@", call.uuid.UUIDString, hangupError);
        } else {
            [self.audioController deactivateAudioSession];
        }
    }
}

- (void)endAllCallsForAccount:(VSLAccount *)account {
    for (VSLCall *call in [self callsForAccount:account]) {
        [self endCall:call completion:nil];
    }
}

/**
 *  Checks if there is a call with the given UUID.
 *
 *  @param UUID The UUID of the call to find.
 *
 *  @retrun A VSLCall object or nil if not found.
 */
- (VSLCall *)callWithUUID:(NSUUID *)uuid {
    DDLogVerbose(@"Looking for a call with UUID:%@", uuid.UUIDString);
    NSUInteger callIndex = [self.calls indexOfObjectPassingTest:^BOOL(VSLCall* _Nonnull call, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([call.uuid isEqual:uuid]) {
            return YES;
        }
        return NO;
    }];

    if (callIndex != NSNotFound) {
        VSLCall *call = [self.calls objectAtIndex:callIndex];
        DDLogDebug(@"VSLCall found for UUID:%@ VSLCall:%@", uuid.UUIDString, call);
        return call;
    }
    DDLogDebug(@"No VSLCall found for UUID:%@", uuid.UUIDString);
    return nil;
}

- (VSLCall *)callWithCallId:(NSInteger)callId {
    NSUInteger callIndex = [self.calls indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        VSLCall *call = (VSLCall *)obj;
        if (call.callId == callId && call.callId != PJSUA_INVALID_ID) {
            return YES;
        }
        return NO;
    }];

    if (callIndex != NSNotFound) {
        return [self.calls objectAtIndex:callIndex];
    }
    return nil;
}

- (NSArray *)callsForAccount:(VSLAccount *)account {
    NSMutableArray *callsForAccount = [[NSMutableArray alloc] init];
    for (VSLCall *call in self.calls) {
        if ([call.account isEqual:account]) {
            [callsForAccount addObject:call];
        }
    }

    if ([callsForAccount count]) {
        return callsForAccount;
    } else {
        return nil;
    }
}

- (VSLCall *)firstCallForAccount:(VSLAccount *)account {
    NSArray *callsForAccount = [self callsForAccount:account];
    if (callsForAccount > 0) {
        return callsForAccount[0];
    } else {
        return nil;
    }
}

- (VSLCall *)firstActiveCallForAccount:(VSLAccount *)account {
    for (VSLCall *call in [self activeCallsForAccount:(VSLAccount *)account]) {
        if (call.callState > VSLCallStateNull && call.callState < VSLCallStateDisconnected) {
            return call;
        }
    }
    return nil;
}

- (NSArray <VSLCall *> *)activeCallsForAccount:(VSLAccount *)account {
    NSMutableArray *activeCallsForAccount = [[NSMutableArray alloc] init];
    for (VSLCall *call in self.calls) {
        if (call.callState > VSLCallStateNull && call.callState < VSLCallStateDisconnected) {
            if ([call.account isEqual:account]) {
                [activeCallsForAccount addObject:call];
            }
        }
    }

    if ([activeCallsForAccount count]) {
        return activeCallsForAccount;
    } else {
        return nil;
    }
}

- (void)reinviteActiveCallsForAccount:(VSLAccount *)account {
    DDLogDebug(@"Reinviting calls");
    for (VSLCall *call in [self activeCallsForAccount:account]) {
        [call reinvite];
    }
}

- (void)callStateChanged:(NSNotification *)notification {
    VSLCall *call = [[notification userInfo] objectForKey:VSLNotificationUserInfoCallKey];
    if (call.callState == VSLCallStateDisconnected) {
        [self removeCall:call];
    }
}
@end
