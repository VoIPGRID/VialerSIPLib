//
//  VSLIpChangeConfiguration.h
//  Copyright © 2018 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VialerPJSIP/pjsua.h>

typedef NS_ENUM(NSInteger, VSLIpChangeConfigurationIpChangeCalls) {
    /**
     * Use the ip change from pjsip.
     */
    VSLIpChangeConfigurationIpChangeCallsDefault,
    /**
     * Do the reinvite of the calls self instead of pjsip.
     */
    VSLIpChangeConfigurationIpChangeCallsReinvite,
    /**
     * Do an UPDATE sip message instead of a INVITE that is done by pjsip.
     */
    VSLIpChangeConfigurationIpChangeCallsUpdate
};
#define VSLEndpointIpChangeCallsString(VSLEndpointIpChangeCalls) [@[@"VSLIpChangeConfigurationIpChangeCallsDefault", @"VSLIpChangeConfigurationIpChangeCallsReinvite", @"VSLIpChangeConfigurationIpChangeCallsUpdate"] objectAtIndex:VSLEndpointIpChangeCalls]

typedef NS_ENUM(NSUInteger, VSLReinviteFlags) {
    /**
     * Deinitialize and recreate media, including media transport. This flag
     * is useful in IP address change situation, if the media transport
     * address (or address family) changes, for example during IPv4/IPv6
     * network handover.
     * This flag is only valid for #pjsua_call_reinvite()/reinvite2(), or
     * #pjsua_call_update()/update2().
     *
     * Warning: If the re-INVITE/UPDATE fails, the old media will not be
     * reverted.
     */
    VSLReinviteFlagsReinitMedia = PJSUA_CALL_REINIT_MEDIA,
    /**
     * Update the local invite session's contact with the contact URI from
     * the account. This flag is only valid for #pjsua_call_set_hold2(),
     * #pjsua_call_reinvite() and #pjsua_call_update(). This flag is useful
     * in IP address change situation, after the local account's Contact has
     * been updated (typically with re-registration) use this flag to update
     * the invite session with the new Contact and to inform this new Contact
     * to the remote peer with the outgoing re-INVITE or UPDATE.
     */
    VSLReinviteFlagsUpdateContact = PJSUA_CALL_UPDATE_CONTACT,
    /**
     * Update the local invite session's Via with the via address from
     * the account. This flag is only valid for #pjsua_call_set_hold2(),
     * #pjsua_call_reinvite() and #pjsua_call_update(). Similar to
     * the flag PJSUA_CALL_UPDATE_CONTACT above, this flag is useful
     * in IP address change situation, after the local account's Via has
     * been updated (typically with re-registration).
     */
    VSLReinviteFlagsUpdateVia = PJSUA_CALL_UPDATE_VIA
};
#define VSLReinviteFlagsString(VSLReinviteFlags) [@[@"VSLReinviteFlagsReinitMedia", @"VSLReinviteFlagsUpdateContact", @"VSLReinviteFlagsUpdateVia"] objectAtIndex:VSLReinviteFlags]

@interface VSLIpChangeConfiguration : NSObject

@property (nonatomic) VSLIpChangeConfigurationIpChangeCalls ipChangeCallsUpdate;

/**
 * Should the old transport be cleaned up.
 */
@property (nonatomic) BOOL ipAddressChangeShutdownTransport;

/**
 * Should all calls be ended when an ip address change has been detected.
 *
 * Default: NO
 */
@property (nonatomic) BOOL ipAddressChangeHangupAllCalls;

/**
 * When ipAddressChangeHangupAllCalls is set to NO, this property should be set.
 *
 * Default: VSLReinviteFlagsReinitMedia | VSLReinviteFlagsUpdateVia | VSLReinviteFlagsUpdateContact
 */
@property (nonatomic) VSLReinviteFlags ipAddressChangeReinviteFlags;

/**
 * Return the default reinvite flags
 */
+ (VSLReinviteFlags)defaultReinviteFlags;
@end
