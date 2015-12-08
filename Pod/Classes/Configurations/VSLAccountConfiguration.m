//
//  VSLAccountConfiguration.m
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import "VSLAccountConfiguration.h"

@implementation VSLAccountConfiguration

- (instancetype)init {
    if (self = [super init]) {
        self.sipAuthRealm = @"*";
        self.sipAuthScheme = @"digest";
    }
    return self;
}

- (NSString *)sipAddress {
    if (self.sipUsername && self.sipDomain) {
        return [NSString stringWithFormat:@"%@@%@", self.sipUsername, self.sipDomain];
    }
    return nil;
}

@end
