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
#import "VSLEndpoint.h"
#import "VSLLogging.h"
#import "VialerSIPLib.h"

#define VSLBlockSafeRun(block, ...) block ? block(__VA_ARGS__) : nil
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
    [account registerAccountWithCompletion:^(BOOL success, NSError * _Nullable error) {
        if (!success) {
            VSLLogError(@"Error registering the account: %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                VSLBlockSafeRun(completion, nil, error);
            });
        } else {
            VSLCall *call = [[VSLCall alloc] initOutboundCallWithNumberToCall:number account:account];
            [self addCall:call];

            CXHandle *numberHandle = [[CXHandle alloc] initWithType:CXHandleTypePhoneNumber value:call.numberToCall];
            CXAction *startCallAction = [[CXStartCallAction alloc] initWithCallUUID:call.uuid handle:numberHandle];

            [self requestCallKitAction:startCallAction completion:^(NSError *error) {
                if (error) {
                    VSLLogError(@"Error requesting \"Start Call Transaction\" error: %@", error);
                    [self removeCall:call];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        VSLBlockSafeRun(completion, nil, error);
                    });
                } else {
                    VSLLogInfo(@"\"Start Call Transaction\" requested succesfully for Call(%@) with account(%ld)", call.uuid.UUIDString, (long)account.accountId);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        VSLBlockSafeRun(completion, call, nil);
                    });
                }
            }];
        }
    }];
}

- (void)answerCall:(VSLCall *)call completion:(void (^)(NSError *error))completion {
    [call answerWithCompletion:completion];
}

- (void)endCall:(VSLCall *)call completion:(void (^)(NSError *error))completion {
    CXAction *endCallAction = [[CXEndCallAction alloc] initWithCallUUID:call.uuid];
    [self requestCallKitAction:endCallAction completion:completion];
    VSLLogInfo(@"\"End Call Transaction\" requested succesfully for Call(%@)", call.uuid.UUIDString);
}

- (void)toggleMuteForCall:(VSLCall *)call completion:(void (^)(NSError *error))completion {
    CXAction *toggleMuteAction = [[CXSetMutedCallAction alloc] initWithCallUUID:call.uuid muted:!call.muted];
    [self requestCallKitAction:toggleMuteAction completion:completion];
    VSLLogInfo(@"\"Mute Call Transaction\" requested succesfully for Call(%@)", call.uuid.UUIDString);
}

- (void)toggleHoldForCall:(VSLCall *)call completion:(void (^)(NSError * _Nullable))completion {
    CXAction *toggleHoldAction = [[CXSetHeldCallAction alloc] initWithCallUUID:call.uuid onHold:!call.onHold];
    [self requestCallKitAction:toggleHoldAction completion:completion];
    VSLLogInfo(@"\"Hold Call Transaction\" requested succesfully for Call(%@)", call.uuid.UUIDString);
}

- (void)sendDTMFForCall :(VSLCall *)call character:(NSString *)character completion:(void (^)(NSError * _Nullable))completion {
    CXAction *dtmfAction = [[CXPlayDTMFCallAction alloc] initWithCallUUID:call.uuid digits:character type:CXPlayDTMFCallActionTypeSingleTone];
    [self requestCallKitAction:dtmfAction completion:completion];
    VSLLogInfo(@"\"Sent DTMF Transaction\" requested succesfully for Call(%@)", call.uuid.UUIDString);
}

- (void)requestCallKitAction:(CXAction *)action completion:(void (^)(NSError *error))completion {
    CXTransaction *transaction = [[CXTransaction alloc] initWithAction:action];
    [self.callController requestTransaction:transaction completion:^(NSError * _Nullable error) {
        if (error) {
            VSLLogError(@"Error requesting transaction: %@. Error:%@", transaction, error);
            dispatch_async(dispatch_get_main_queue(), ^{
                VSLBlockSafeRun(completion,error);
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                VSLBlockSafeRun(completion,nil);
            });
        }
    }];
}

- (void)addCall:(VSLCall *)call {
    [self.calls addObject:call];
    VSLLogVerbose(@"Call(%@) added. Calls count:%ld",call.uuid.UUIDString, (long)[self.calls count]);
}

- (void)removeCall:(VSLCall *)call {
    [self.calls removeObject:call];

    if ([self.calls count] == 0) {
        self.calls = nil;
        self.audioController = nil;
    }
    VSLLogVerbose(@"Call(%@) removed. Calls count: %ld",call.uuid.UUIDString, (long)[self.calls count]);
}

- (void)endAllCalls {
    if ([self.calls count] == 0) {
        return;
    }
    
    for (VSLCall *call in self.calls) {
        VSLLogVerbose(@"Ending call: %@", call.uuid.UUIDString);
        NSError *hangupError;
        [call hangup:&hangupError];
        if (hangupError) {
            VSLLogError(@"Could not hangup call(%@). Error: %@", call.uuid.UUIDString, hangupError);
        } else {
            [self.audioController deactivateAudioSession];
        }
        [self removeCall:call];
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
 *  @param uuid The UUID of the call to find.
 *
 *  @retrun A VSLCall object or nil if not found.
 */
- (VSLCall *)callWithUUID:(NSUUID *)uuid {
    VSLLogVerbose(@"Looking for a call with UUID:%@", uuid.UUIDString);
    NSUInteger callIndex = [self.calls indexOfObjectPassingTest:^BOOL(VSLCall* _Nonnull call, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([call.uuid isEqual:uuid] && uuid) {
            return YES;
        }
        return NO;
    }];

    if (callIndex != NSNotFound) {
        VSLCall *call = [self.calls objectAtIndex:callIndex];
        VSLLogDebug(@"VSLCall found for UUID:%@ VSLCall:%@", uuid.UUIDString, call);
        return call;
    }
    VSLLogDebug(@"No VSLCall found for UUID:%@", uuid.UUIDString);
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
    if ([self.calls count] == 0) {
        return nil;
    }

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
    return [callsForAccount firstObject];
}

- (VSLCall *)firstActiveCallForAccount:(VSLAccount *)account {
    for (VSLCall *call in [self activeCallsForAccount:(VSLAccount *)account]) {
        if (call.callState > VSLCallStateNull && call.callState < VSLCallStateDisconnected) {
            return call;
        }
    }
    return nil;
}

- (VSLCall *)lastCallForAccount:(VSLAccount *)account {
    NSArray *callsForAccount = [self callsForAccount:account];
    return [callsForAccount lastObject];
}

- (NSArray <VSLCall *> *)activeCallsForAccount:(VSLAccount *)account {
    if ([self.calls count] == 0) {
        
    }

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
    VSLLogDebug(@"Reinviting calls");
    for (VSLCall *call in [self activeCallsForAccount:account]) {
        [call reinvite];
    }
}

- (void)updateActiveCallsForAccount:(VSLAccount *)account {
    VSLLogDebug(@"Sent UPDATE for calls");
    for (VSLCall *call in [self activeCallsForAccount:account]) {
        [call update];
    }
}

- (void)callStateChanged:(NSNotification *)notification {
    __weak VSLCall *call = [[notification userInfo] objectForKey:VSLNotificationUserInfoCallKey];
    if (call.callState == VSLCallStateDisconnected) {
        [self removeCall:call];
    }
}
@end
