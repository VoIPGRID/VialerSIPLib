//
//  VSLStunConfiguration.m
//  Copyright © 2018 Devhouse Spindle. All rights reserved.
//

#import "VSLStunConfiguration.h"

@implementation VSLStunConfiguration

- (NSArray *)stunServers {
    if (!_stunServers) {
        _stunServers = [NSArray array];
    }
    return _stunServers;
}

- (int)numOfStunServers {
    return (int)self.stunServers.count;
}

@end
