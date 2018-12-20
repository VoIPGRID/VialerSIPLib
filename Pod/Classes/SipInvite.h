#import <Foundation/Foundation.h>

@interface SipInvite : NSObject

/**
 Create this SipInvite object using the full INVITE packet.
 
 @param packet The full SIP INVITE packet.
 @return An instance of SipInvite
 */
- (instancetype _Nullable)initWithInvitePacket:(char*_Nonnull)packet;

/**
 Check if this INVITE contained a REMOTE-PARTY-ID SIP header.
 
 @return TRUE if the INVITE contained the header, otherwise FALSE.
 */
- (bool) hasRemotePartyId;

/**
 Get the caller id from the REMOTE-PARTY-ID SIP header.
 
 @return The caller id from the REMOTE-PARTY-ID SIP header.
 */
- (NSString *_Nullable) getRemotePartyIdNumber;

/**
 Get the name from the REMOTE-PARTY-ID SIP header.
 
 @return The name from the REMOTE-PARTY-ID SIP header.
 */
- (NSString *_Nullable) getRemotePartyIdName;

/**
 Check if this INVITE contained a P-ASSERTED-IDENTITY SIP header.
 
 @return TRUE if the INVITE contained the header, otherwise FALSE.
 */
- (bool) hasPAssertedIdentity;

/**
 Get the caller id from the P-ASSERTED-IDENTITY SIP header.
 
 @return The caller id from the P-ASSERTED-IDENTITY SIP header.
 */
- (NSString *_Nullable) getPAssertedIdentityNumber;

/**
 Get the name from the P-ASSERTED-IDENTITY SIP header.
 
 @return The name from the P-ASSERTED-IDENTITY SIP header.
 */
- (NSString *_Nullable) getPAssertedIdentityName;

@end
