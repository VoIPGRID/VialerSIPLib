//
//  VSLCall.h
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VSLAccount.h"
#import <VialerPJSIP/pjsua.h>

/**
 *  Notification that will be posted when a phonecall is connected.
 */
extern NSString * _Nonnull const VSLCallConnectedNotification;
/**
 *  Notification that will be posted when a phonecall is disconnected.
 */
extern NSString * _Nonnull const VSLCallDisconnectedNotification;

/**
 *  The posible errors VSLCall can return.
 */
typedef NS_ENUM(NSInteger, VSLCallErrors) {
    /**
     *  Unable to create a PJSip thread.
     */
    VSLCallErrorCannotCreateThread,
    /**
     *  Unable to create call.
     */
    VSLCallErrorCannotCreateCall,
    /**
     *  Unable to hangup call.
     */
    VSLCallErrorCannotHangupCall,
    /**
     *  Unable to decline call.
     */
    VSLCallErrorCannotDeclineCall,
    /**
     *  Unable to toggle mute call.
     */
    VSLCallErrorCannotToggleMute,
    /**
     *  Unable to toggle hold call.
     */
    VSLCallErrorCannotToggleHold,
    /**
     *  Unable to send DTMF for call.
     */
    VSLCallErrorCannotSendDTMF,
};
#define VSLCallErrorsString(VSLCallErrors) [@[@"VSLCallErrorCannotCreateThread", @"VSLCallErrorCannotCreateCall", @"VSLCallErrorCannotHangupCall", @"VSLCallErrorCannotDeclineCall", @"VSLCallErrorCannotToggleMute", @"VSLCallErrorCannotToggleHold", @"VSLCallErrorCannotSendDTMF"] objectAtIndex:VSLCallErrors]


/**
 *  The states which a call can have.
 */
typedef NS_ENUM(NSInteger, VSLCallState) {
    /**
     *   Before INVITE is sent or received.
     */
    VSLCallStateNull = PJSIP_INV_STATE_NULL,
    /**
     *   After INVITE is sent.
     */
    VSLCallStateCalling = PJSIP_INV_STATE_CALLING,
    /**
     *  After INVITE is received.
     */
    VSLCallStateIncoming = PJSIP_INV_STATE_INCOMING,
    /**
     *  After response with To tag.
     */
    VSLCallStateEarly = PJSIP_INV_STATE_EARLY,
    /**
     *  After 2xx is sent/received.
     */
    VSLCallStateConnecting = PJSIP_INV_STATE_CONNECTING,
    /**
     *  After ACK is sent/received.
     */
    VSLCallStateConfirmed = PJSIP_INV_STATE_CONFIRMED,
    /**
     *  Session is terminated.
     */
    VSLCallStateDisconnected = PJSIP_INV_STATE_DISCONNECTED,
};
#define VSLCallStateString(VSLCallState) [@[@"VSLCallStateNull", @"VSLCallStateCalling", @"VSLCallStateIncoming", @"VSLCallStateEarly", @"VSLCallStateConnecting", @"VSLCallStateConfirmed", @"VSLCallStateDisconnected"] objectAtIndex:VSLCallState]


/**
 *  The states which the media can have.
 */
typedef NS_ENUM(NSInteger, VSLMediaState) {
    /**
     *  There is no media.
     */
    VSLMediaStateNone = PJSUA_CALL_MEDIA_NONE,
    /**
     *  The media is active.
     */
    VSLMediaStateActive = PJSUA_CALL_MEDIA_ACTIVE,
    /**
     *  The media is locally on hold.
     */
    VSLMediaStateLocalHold = PJSUA_CALL_MEDIA_LOCAL_HOLD,
    /**
     *  The media is remote on hold.
     */
    VSLMediaStateRemoteHold = PJSUA_CALL_MEDIA_REMOTE_HOLD,
    /**
     *  There is an error with the media.
     */
    VSLMediaStateError = PJSUA_CALL_MEDIA_ERROR,
};
#define VSLMediaStateString(VSLMediaState) [@[@"VSLMediaStateNone", @"VSLMediaStateActive", @"VSLMediaStateLocalHold", @"VSLMediaStateRemoteHold", @"VSLMediaStateError"] objectAtIndex:VSLMediaState]

typedef  NS_ENUM(NSInteger, VSLCallTransferState) {
    VSLCallTransferStateUnkown,
    VSLCallTransferStateInitialized,
    VSLCallTransferStateTrying = PJSIP_SC_TRYING,
    VSLCallTransferStateAccepted = PJSIP_SC_OK,
};
#define VSLCallTransferStateString(VSLCallTransferState) [@[@"VSLCallTransferStateUnkown", @"VSLCallTransferStateInitialized", @"VSLCallTransferStateTrying", @"VSLCallTransferStateAccepted"] objectAtIndex:VSLCallTransferState]

@interface VSLCall : NSObject

#pragma mark - Properties

/**
*  The callId which a call receives when it is created.
*/
@property (readonly, nonatomic) NSInteger callId;

/**
 * The accountId the call belongs to.
 */
@property (readonly, nonatomic) NSInteger accountId;

/**
 *  The VSLAccount the call belongs to.
 */
@property (readonly, nonatomic) VSLAccount * _Nonnull account;

/**
 *  The state in which the call currently has.
 */
@property (readonly, nonatomic) VSLCallState callState;

/**
 *  The state text which the call currently has.
 */
@property (readonly, nonatomic) NSString * _Nullable callStateText;

/**
 *  The last status code the call had.
 */
@property (readonly, nonatomic) NSInteger lastStatus;

/**
 *  The last status text the call had.
 */
@property (readonly, nonatomic) NSString * _Nullable lastStatusText;

/**
 *  The state in which the media of the call currently is.
 */
@property (readonly, nonatomic) VSLMediaState mediaState;

/**
 *  The local URI of the call.
 */
@property (readonly, nonatomic) NSString * _Nullable localURI;

/**
 *  The remote URI of the call.
 */
@property (readonly, nonatomic) NSString * _Nullable remoteURI;

/**
 *  The name of the caller.
 */
@property (readonly, nonatomic) NSString * _Nullable callerName;

/**
 *  The number of the caller.
 */
@property (readonly, nonatomic) NSString * _Nullable callerNumber;

/**
 *  True if the call was incoming.
 */
@property (readonly, getter=isIncoming) BOOL incoming;

/**
 *  True if the microphone is muted.
 */
@property (readonly, nonatomic) BOOL muted;

/**
 *  True if the call is in speaker mode.
 */
@property (readonly, nonatomic) BOOL speaker;

/**
 *  True if the call is on hold locally.
 */
@property (readonly, nonatomic) BOOL onHold;

/**
 *  The statie in which the transfer of the call currently is.
 */
@property (readonly, nonatomic) VSLCallTransferState transferStatus;

#pragma mark - Stats

/**
 *  Calculated amount of data transferred (Receiving & Transmitting).
 */
@property (readonly, nonatomic) float totalMBsUsed;

/**
 *  Calculated R score of the call.
 *
 *  R score is a way to calculate the quality of a phone call.
 *
 *  Ranges 0 to 93.2, where 0 is very bad quality and 93.2 is best quality possible.
 */
@property (readonly, nonatomic) float R;

/**
 *  Calculated MOS score of the call.
 *
 *  Based on Mean Opinion Score for calls, see: https://en.wikipedia.org/wiki/Mean_opinion_score
 *  Ranges from 1 to 4.4 (slighty different than on wiki). Translates to:
 *
 *  MOS     Quality     Impairment
 *  5       Excellent	Imperceptible
 *  4       Good        Perceptible but not annoying
 *  3       Fair        Slightly annoying
 *  2       Poor        Annoying
 *  1       Bad         Very annoying
 */
@property (readonly, nonatomic) float MOS;

/**
 *  Calculate MOS score & data use of call.
 */
- (void)calculateStats;

#pragma mark - Methods

/**
 *  This will setup a call to the given number and attached to the account.
 *
 *  @param number  The number that should be called.
 *  @param account The account to which the call should be added.
 *  @param error   Pointer to an NSError pointer. Will be set to a NSError instance if cannot setup the call.
 *
 *  @return VSLCall instance
 */
+ (instancetype _Nullable)callNumber:(NSString * _Nonnull)number withAccount:(VSLAccount * _Nonnull)account error:(NSError * _Nullable * _Nullable)error;

/**
 *  This will create a call instance with the given accountId.
 *
 *  @param callId    The id of the call.
 *  @param accountId The id of the account to which the call should be added.
 *
 *  @return VSLCall instance
 */
- (instancetype _Nullable)initWithCallId:(NSUInteger)callId accountId:(NSInteger)accountId;

/**
 *  This will change the callState of the call.
 *
 *  @param callInfo pjsip callInfo
 */
- (void)callStateChanged:(pjsua_call_info)callInfo;

/**
 *  This will change the mediaState of the call.
 *
 *  @param callInfo pjsip callInfo
 */
- (void)mediaStateChanged:(pjsua_call_info)callInfo;

/**
 *  This will end the call.
 *
 *  @param error Pointer to an NSError pointer. Will be set to a NSError instance if cannot hangup the call.
 *
 *  @return BOOL success of hanging up the call.
 */
- (BOOL)hangup:(NSError * _Nullable * _Nullable)error;

/**
 *  This will decline the incoming call.
 *
 *  @param error Pointer to an NSError pointer. Will be set to a NSError instance if cannot decline the call.
 *
 *  @return BOOL success of declining up the call.
 */
- (BOOL)decline:(NSError * _Nullable * _Nullable)error;

/**
 *  Toggle mute of the microphone for this call.
 *
 *  @param error Pointer to an NSError pointer. Will be set to a NSError instance if cannot toggle mute of the call.
 */
- (BOOL)toggleMute:(NSError * _Nullable * _Nullable)error;

/**
 *  This will answer the incoming call.
 *
 *  @param error Pointer to an NSError pointer. Will be set to a NSError instance if cannot answer the call.
 *
 *  @return BOOL success of answering the call.
 */
- (BOOL)answer:(NSError * _Nullable * _Nullable)error;

/**
 *  Toggle speaker mode of the call.
 *
 *  @param error Pointer to an NSError pointer. Will be set to a NSError instance if cannot put call in speaker mode.
 */
- (void)toggleSpeaker;

/**
 *  Toggle hold of the call.
 *
 *  @param error Pointer to an NSError pointer. Will be set to a NSError instance if cannot put call on hold.
 */
- (BOOL)toggleHold:(NSError * _Nullable * _Nullable)error;

/**
 *  Send DTMF tone for this call with a character.
 *
 *  @param character character NSString the character for the DTMF.
 *  @param error     error Pointer to an NSError pointer. Will be set to a NSError instance if cannot send DTMF for the call.
 */
- (BOOL)sendDTMF:(NSString * _Nonnull)character error:(NSError * _Nullable * _Nullable)error;

/**
 *  Transfer the call to the given VSLCall.
 *
 *  @param secondCall VSLCall this call should be transferred to.
 *
 *  @return BOOL success of the call transfer.
 */
- (BOOL)transferToCall:(VSLCall * _Nonnull)secondCall;

/**
 *  This will change the transferStatus of the call.
 *
 *  @param statusCode The status code of the transfer state.
 *  @param text       The description of the transfer state.
 *  @param final      BOOL indictating this is the last update of the transfer state.
 */
- (void)callTransferStatusChangedWithStatusCode:(NSInteger)statusCode statusText:(NSString * _Nullable)text final:(BOOL)final;

/**
 *  Will re-invite call.
 */
- (void)reinvite;

@end
