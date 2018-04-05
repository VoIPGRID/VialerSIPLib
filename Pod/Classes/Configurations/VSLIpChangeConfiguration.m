//
//  VSLIpChangeConfiguration.m
//  Copyright © 2018 Devhouse Spindle. All rights reserved.
//

#import "VSLIpChangeConfiguration.h"

@implementation VSLIpChangeConfiguration

- (instancetype)init {
    if (self = [super init]) {
        self.ipChangeCallsUpdate = VSLIpChangeConfigurationIpChangeCallsDefault;
        self.ipAddressChangeShutdownTransport = YES;
        self.ipAddressChangeHangupAllCalls = NO;
        self.ipAddressChangeReinviteFlags = VSLReinviteFlagsReinitMedia | VSLReinviteFlagsUpdateVia | VSLReinviteFlagsUpdateContact;
    }
    return self;
}

+ (VSLReinviteFlags)defaultReinviteFlags {
    return VSLReinviteFlagsReinitMedia | VSLReinviteFlagsUpdateVia | VSLReinviteFlagsUpdateContact;
}

@end
