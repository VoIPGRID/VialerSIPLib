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
        self.dropCallOnRegistrationFailure = NO;
        self.mediaStunType = VSLStunUseDefault;
        self.sipStunType = VSLStunUseDefault;
        self.contactRewriteMethod = VSLContactRewriteMethodAlwaysUpdate;
        self.contactUseSrcPort = YES;
        self.allowViaRewrite = NO;
        self.allowContactRewrite = YES;
    }
    return self;
}

- (NSString *)sipAddress {
    if (self.sipAccount && self.sipDomain) {
        return [NSString stringWithFormat:@"%@@%@", self.sipAccount, self.sipDomain];
    }
    return nil;
}

@end
