//
//  VSLCallManager.h
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "VSLAudioController.h"

@class VSLCall;
@class VSLAccount;

/**
 *  The VSLCallManager class is the single point of entry for everything you want to do with a call.
 *  - start an outbound call
 *  - end a call
 *  - mute or hold a call
 *  - sent DTMF signals
 *
 *  It takes care the CallKit (if available) and PJSIP interactions.
 */
@interface VSLCallManager : NSObject

/**
 *  Controler responsible for managing the audio streams for the calls.
 */
@property (readonly) VSLAudioController * _Nonnull audioController;

/**
 *  Start a call to the given number for the given account.
 *
 *  @param number The number to call.
 *  @param account The account to use for the call
 *  @param completion A completion block which is always invoked. Either the call is started successfully and you can obtain an
 *  VSLCall instance throught the block or, when the call fails, you can query the blocks error parameter.
 */
- (void)startCallToNumber:(NSString * _Nonnull)number forAccount:(VSLAccount * _Nonnull)account completion:(void (^_Nonnull )(VSLCall * _Nullable call, NSError * _Nullable error))completion;

/**
 *  Answers the given inbound call.
 *
 *  #param completion A completion block giving access to an NSError when unable to answer the given call.
 */
- (void)answerCall:(VSLCall * _Nonnull)call completion:(void (^ _Nonnull)(NSError * _Nullable error))completion;

/**
 *  End the given call.
 *
 *  @param call The VSLCall instance to end.
 *  @param completion A completion block giving access to an NSError when the given call could not be ended.
 */
- (void)endCall:(VSLCall * _Nonnull)call completion:(void (^ _Nullable)(NSError * _Nullable error))completion;

/**
 *  Toggle mute of the microphone for this call.
 *
 *  @param completion A completion block giving access to an NSError when mute cannot be toggle for the given call.
 */
- (void)toggleMuteForCall:(VSLCall * _Nonnull)call completion:(void (^ _Nonnull)(NSError * _Nullable error))completion;

/**
 *  Toggle hold of the call.
 *
 *  @param completion A completion block giving access to an NSError when the given call cannot be put on hold.
 */
- (void)toggleHoldForCall:(VSLCall * _Nonnull)call completion:(void (^ _Nonnull)(NSError * _Nullable error))completion;

/**
 *  Send DTMF tone for this call with a character.
 *
 *  @param character character NSString the character for the DTMF.
 *  @param completion A completion block giving access to an NSError when sending DTMF fails.
 */
- (void)sendDTMFForCall:(VSLCall * _Nonnull)call character:(NSString * _Nonnull)character completion:(void (^ _Nonnull)(NSError * _Nullable error))completion;

/**
 *  Find a call with the given UUID.
 *
 *  @param uuid The UUID of the call to find.
 *
 *  @return A VSLCall instance if a call was found for the given UUID, otherwise nil.
 */
- (VSLCall * _Nullable)callWithUUID:(NSUUID * _Nonnull)uuid;

/**
 *  Find a call for the given call ID.
 *
 *  @param callId The PJSIP generated call ID given to an incoming call.
 *
 *  @return A VSLCall instance if a call with the given call ID was found, otherwise nil.
 */
- (VSLCall * _Nullable)callWithCallId:(NSInteger)callId;

/**
 *  Returns all the calls for a given account.
 *
 * @param account The VSLAccount for which to find it's calls.
 *
 * @return An NSArray containing all the accounts calls or nil.
 */
- (NSArray * _Nullable)callsForAccount:(VSLAccount * _Nonnull)account;

/**
 *  Add the given call to the Call Manager.
 *
 *  @param call The VSLCall instance to add.
 */
- (void)addCall:(VSLCall * _Nonnull)call;

/**
 *  Remove the given call from the Call Manager.
 *
 *  @param call the VSLCall instance to remove.
 */
- (void)removeCall:(VSLCall * _Nonnull)call;

/**
 *  End all calls.
 */
- (void)endAllCalls;

/**
 *  End all calls for the given account.
 *
 *  @param account The VSLAccount instance for which to end all calls.
 */
- (void)endAllCallsForAccount:(VSLAccount * _Nonnull)account;

/**
 *  Returns the first call for the given account
 *
 *  @param account The VSLAccount instance for which to return the first call.
 *
 *  @return The first call for the given account, otherwise nil.
 */
- (VSLCall * _Nullable)firstCallForAccount:(VSLAccount * _Nonnull)account;

/**
 *  Returns the first ACTIVE call for the given account.
 *
 *  @param account The VSLAccount instance for which to return the first active call.
 *
 *  @return The first active call for the given account, otherwise nil.
 */
- (VSLCall * _Nullable)firstActiveCallForAccount:(VSLAccount * _Nonnull)account;

/**
 *  Returns the last call for the given account
 *
 *  @param account The VSLAccount instance for which to return the last call.
 *
 *  @return The last call for the given account, otherwise nil.
 */
- (VSLCall * _Nullable)lastCallForAccount:(VSLAccount * _Nonnull)account;

/**
 *  Reinvite all active calls for the given account.
 *
 *  @param account The VSLAccount instance for which to reinvite all calls.
 */
- (void)reinviteActiveCallsForAccount:(VSLAccount * _Nonnull)account;

/**
 *  Sent a SIP UPDATE message to all active calls for the given account.
 *
 *  @param account The VSLAccount instance for which to sent the UPDATE.
 */
- (void)updateActiveCallsForAccount:(VSLAccount * _Nonnull)account;
@end
