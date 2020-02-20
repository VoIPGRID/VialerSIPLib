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
     * Follow the default setting in the global pjsua_config.
     */
    VSLStunUseDefault = PJSUA_STUN_USE_DEFAULT,
    /**
     * Disable STUN. If STUN is not enabled in the global pjsua_config,
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

/**
 *  Enum which specifies the contact rewrite method
 */
typedef NS_ENUM(NSUInteger, VSLContactRewriteMethod) {
    /**
     * The Contact update will be done by sending unregistration
     * to the currently registered Contact, while simultaneously sending new
     * registration (with different Call-ID) for the updated Contact.
     */
    VSLContactRewriteMethodUnregister = PJSUA_CONTACT_REWRITE_UNREGISTER,
    /**
     * The Contact update will be done in a single, current
     * registration session, by removing the current binding (by setting its
     * Contact's expires parameter to zero) and adding a new Contact binding,
     * all done in a single request.
     */
    VSLContactRewriteMethodNoUnregister = PJSUA_CONTACT_REWRITE_NO_UNREG,
    /**
     * The Contact update will be done when receiving any registration final
     * response. If this flag is not specified, contact update will only be
     * done upon receiving 2xx response. This flag MUST be used with
     * PJSUA_CONTACT_REWRITE_UNREGISTER or PJSUA_CONTACT_REWRITE_NO_UNREG
     * above to specify how the Contact update should be performed when
     * receiving 2xx response.
     */
    
    VSLContactRewriteMethodAlwaysUpdate = PJSUA_CONTACT_REWRITE_ALWAYS_UPDATE
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
 *
 *  Default: NO
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

/**
 * Control how Contact update will be done with the registration.
 *
 * Default: VSLContactRewriteMethodAlwaysUpdate
 */
@property (nonatomic) VSLContactRewriteMethod contactRewriteMethod;

/**
 * Specify if source TCP port should be used as the initial Contact
 * address if TCP/TLS transport is used. Note that this feature will
 * be automatically turned off when nameserver is configured because
 * it may yield different destination address due to DNS SRV resolution.
 * Also some platforms are unable to report the local address of the
 * TCP socket when it is still connecting. In these cases, this
 * feature will also be turned off.
 *
 *  Default: YES
 */
@property (nonatomic) BOOL contactUseSrcPort;

/**
 * This option is used to update the transport address and the Contact
 * header of REGISTER request. When this option is  enabled, the library
 * will keep track of the public IP address from the response of REGISTER
 * request. Once it detects that the address has changed, it will
 * unregister current Contact, update the Contact with transport address
 * learned from Via header, and register a new Contact to the registrar.
 * This will also update the public name of UDP transport if STUN is
 * configured.
 *
 *  Default: YES
 */
@property (nonatomic) BOOL allowContactRewrite;

/**
 * This option is used to overwrite the "sent-by" field of the Via header
 * for outgoing messages with the same interface address as the one in
 * the REGISTER request, as long as the request uses the same transport
 * instance as the previous REGISTER request.
 *
 *  Default: YES
 */
@property (nonatomic) BOOL allowViaRewrite;

@property (nonatomic) VSLTurnConfiguration * _Nullable turnConfiguration;

@property (nonatomic) VSLIceConfiguration * _Nullable iceConfiguration;

@end

