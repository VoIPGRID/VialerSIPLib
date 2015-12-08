//
//  VSLTransportConfiguration.h
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <VialerPJSIP/pjsip/sip_types.h>

/**
 The available transports to configure.
 */
typedef NS_ENUM(NSUInteger, VSLTransportType) {
    VSLTransportTypeUDP = PJSIP_TRANSPORT_UDP,
    VSLTransportTypeTCP = PJSIP_TRANSPORT_TCP,
    VSLTransportTypeUDP6 = PJSIP_TRANSPORT_UDP6,
    VSLTransportTypeTCP6 = PJSIP_TRANSPORT_TCP6
};

@interface VSLTransportConfiguration : NSObject
@property (nonatomic) VSLTransportType transportType;

/**
 */
@property (nonatomic) NSUInteger port;

/**
 */
@property (nonatomic) NSUInteger portRange;

/**
 This function will init a VSLTransportConfiguration with default settings and the it will
 set the VSLTransport type which has been passed in as parameter.

 @param transportType
 */
+ (instancetype _Nullable)configurationWithTransportType:(VSLTransportType)transportType;

@end
