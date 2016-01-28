//
//  VSLCall.h
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VSLAccount.h"
#import <VialerPJSIP/pjsua.h>

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
    VSLCallEarlyState = PJSIP_INV_STATE_EARLY,
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

/**
 *  The states which the media can have.
 */
typedef NS_ENUM(NSInteger, VSLMediaState) {
    /**
     *  There is no media.
     */
    VSLMediaStateNone = PJSUA_CALL_MEDIA_NONE,
    /**
     *  There is an error with the media.
     */
    VSLMediaStateError = PJSUA_CALL_MEDIA_ERROR,
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
    VSLMediaStateRemoteHold = PJSUA_CALL_MEDIA_REMOTE_HOLD
};

@interface VSLCall : NSObject

/**
*  The callId which a call receives when it is created.
*/
@property (readonly, nonatomic) NSInteger callId;

/**
 * The accountId the call belongs to.
 */
@property (readonly, nonatomic) NSInteger accountId;

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
 *  This will create a call instance and with the given accountId.
 *
 *  @param callId    The id of the call.
 *  @param accountId The id of the account to which the call should be added.
 *
 *  @return VSLCall instance
 */
+ (instancetype _Nullable)callWithId:(NSInteger)callId andAccountId:(NSInteger)accountId;

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
 *  Toggle mute of the microphone for this call.
 *
 *  @param error Pointer to an NSError pointer. Will be set to a NSError instance if cannot toggle mute of the call.
 */
- (void)toggleMute:(NSError * _Nullable * _Nullable)error;

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
- (void)toggleHold:(NSError * _Nullable * _Nullable)error;

/**
 *  Send DTMF tone for this call with a character.
 *
 *  @param character character NSString the character for the DTMF.
 *  @param error     error Pointer to an NSError pointer. Will be set to a NSError instance if cannot send DTMF for the call.
 */
- (void)sendDTMF:(NSString * _Nonnull)character error:(NSError * _Nullable * _Nullable)error;
@end
