//
//  VSLAccountConfiguration.h
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VSLIceConfiguration.h"
#import "VSLTurnConfiguration.h"
#include <VialerPJSIP/pjsua.h>

/**
 *  The available stun to configure.
 */
typedef NS_ENUM(NSUInteger, VSLStunUse) {
    /**
     * Follow the default setting in the global \a pjsua_config.
     */
    VSLStunUseDefault = PJSUA_STUN_USE_DEFAULT,
    /**
     * Disable STUN. If STUN is not enabled in the global \a pjsua_config,
     * this setting has no effect.
     */
    VSLStunUseDisable = PJSUA_STUN_USE_DISABLED,
    /**
     * Retry other STUN servers if the STUN server selected during
     * startup (#pjsua_init()) or after calling #pjsua_update_stun_servers()
     * is unavailable during runtime. This setting is valid only for
     * account's media STUN setting and if the call is using UDP media
     * transport.
     */
    VSLStunUseRetryOnFailure = PJSUA_STUN_RETRY_ON_FAILURE
};

typedef NS_ENUM(NSUInteger, VSLContactRewriteMethod) {
    VSLContactRewriteMethodUnregister = PJSUA_CONTACT_REWRITE_UNREGISTER,
    VSLContactRewriteMethodNoUnregister = PJSUA_CONTACT_REWRITE_NO_UNREG,
    VSLContactRewriteMethodAlwaysUpdate = PJSUA_CONTACT_REWRITE_ALWAYS_UPDATE
};

typedef NS_ENUM(NSUInteger, VSLReinviteFlags) {
    VSLReinviteFlagsReinitMedia = PJSUA_CALL_REINIT_MEDIA,
    VSLReinviteFlagsUpdateContact = PJSUA_CALL_UPDATE_CONTACT,
    VSLReinviteFlagsUpdateVia = PJSUA_CALL_UPDATE_VIA
};

@interface VSLAccountConfiguration : NSObject

/**
 *  The account that should be used when authenticate on remote PBX.
 */
@property (strong, nonatomic) NSString * _Nonnull sipAccount;

/**
 *  The password that should be used when authenticate on remote PBX.
 */
@property (strong, nonatomic) NSString * _Nonnull sipPassword;

/**
 *  The domain where the PBX can be found.
 */
@property (strong, nonatomic) NSString * _Nonnull sipDomain;

/**
 *  The proxy address where to connect to.
 */
@property (strong, nonatomic) NSString * _Nonnull sipProxyServer;

/**
 *  The address which is a combination of sipAccount & sipDomain.
 */
@property (readonly, nonatomic) NSString * _Nonnull sipAddress;

/**
 *  The authentication realm.
 *
 *  Default: *
 */
@property (strong, nonatomic) NSString * _Nonnull sipAuthRealm;

/**
 *  The authentication scheme.
 *
 *  Default: digest
 */
@property (strong, nonatomic) NSString * _Nonnull sipAuthScheme;

/**
 *  If YES the account will be registered when added to the endpoint.
 *
 *  Default: NO
 */
@property (nonatomic) BOOL sipRegisterOnAdd;

/**
 *  If YES, the account presence will be published to the server where the account belongs.
 */
@property (nonatomic) BOOL sipPublishEnabled;

/**
 *  If YES all current calls will be hungup when a registation failure is detected.
 */
@property (nonatomic) BOOL dropCallOnRegistrationFailure;

/**
 *  The stun type that should be used.
 */
@property (nonatomic) pjsua_stun_use sipStunType;

/**
 *  The media stun type that should be used.
 */
@property (nonatomic) pjsua_stun_use mediaStunType;

@property (nonatomic) BOOL allowContactRewrite;
@property (nonatomic) VSLContactRewriteMethod contactRewriteMethod;
@property (nonatomic) BOOL contactUseSrcPort;
@property (nonatomic) BOOL allowViaRewrite;


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

@property (nonatomic) VSLTurnConfiguration * _Nullable turnConfiguration;

@property (nonatomic) VSLIceConfiguration * _Nullable iceConfiguration;

@end

