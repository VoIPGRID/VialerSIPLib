//
//  VSLTransportConfiguration.h
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <VialerPJSIP/pjsip/sip_types.h>

/**
 *  The available transports to configure.
 */
typedef NS_ENUM(NSUInteger, VSLTransportType) {
    /**
     *  UDP
     */
    VSLTransportTypeUDP = PJSIP_TRANSPORT_UDP,
    /**
     *  UDP6
     */
    VSLTransportTypeUDP6 = PJSIP_TRANSPORT_UDP6,
    /**
     *  TCP
     */
    VSLTransportTypeTCP = PJSIP_TRANSPORT_TCP,
    /**
     *  TCP6
     */
    VSLTransportTypeTCP6 = PJSIP_TRANSPORT_TCP6,
    /**
     * TLS
     */
    VSLTransportTypeTLS = PJSIP_TRANSPORT_TLS,
    /**
     * TLS6
     */
    VSLTransportTypeTLS6 = PJSIP_TRANSPORT_TLS6

};
#define VSLTransportTypeString(VSLTransportType) [@[@"VSLTransportTypeUDP", @"VSLTransportTpeUDP6", @"VSLTransportTypeTCP", @"VSLTransportTypeTCP6", @"VSLTransportTypeTLS", @"VSLTransportTypeTLS6"] objectAtIndex:VSLTransportType]

@interface VSLTransportConfiguration : NSObject
/**
 *  The transport type that should be used.
 */
@property (nonatomic) VSLTransportType transportType;

/**
 *  The port on which the communication should be set up.
 */
@property (nonatomic) NSUInteger port;

/**
 *  The port range that should be used.
 */
@property (nonatomic) NSUInteger portRange;

/**
 *  This function will init a VSLTransportConfiguration with default settings
 *
 *  @param transportType Transport type that will be set.
 *
 *  @return VSLTransportConfiguration instance.
 */
+ (instancetype _Nullable)configurationWithTransportType:(VSLTransportType)transportType;

#define VSLTransportStateName(pjsip_transport_state) [@[@"PJSIP_TP_STATE_CONNECTED", @"PJSIP_TP_STATE_DISCONNECTED", @"PJSIP_TP_STATE_SHUTDOWN", @"PJSIP_TP_STATE_DESTROY"] objectAtIndex:pjsip_transport_state]

@end
