//
//  VialerSIPLib.m
//  Copyright © 2015 voipgrid.com. All rights reserved.
//

#import "VialerSIPLib.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

#import "VSLAccount.h"
#import "VSLEndpoint.h"
#import "VSLCall.h"

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
@implementation VialerSIPLib

- (instancetype)init {
    if (self = [super init]) {

    }
    return self;
}

- (VSLCall *)callNumber:(NSString *)number {
    //Create an account
    VSLAccount *account = [[VSLAccount alloc] init];
    [[VSLEndpoint sharedEndpoint] addAccount:account];

    return [[VSLCall alloc] init];
}

@end
