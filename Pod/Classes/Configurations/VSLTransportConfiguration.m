//
//  VSLTransportConfiguration.m
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import "VSLTransportConfiguration.h"

static NSInteger const VSLTransportConfigurationPort = 5060;
static NSInteger const VSLTransportConfigurationPortRange = 0;

@implementation VSLTransportConfiguration

- (instancetype)init {
    if (self = [super init]) {
        self.port = VSLTransportConfigurationPort;
        self.portRange = VSLTransportConfigurationPortRange;
        self.transportType = VSLTransportTypeTCP;
    }
    return self;
}

+ (instancetype)configurationWithTransportType:(VSLTransportType)transportType {
    VSLTransportConfiguration *transportConfiguration = [[VSLTransportConfiguration alloc] init];
    transportConfiguration.transportType = transportType;
    return transportConfiguration;
}

@end
