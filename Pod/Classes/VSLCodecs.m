//
//  VSLCodecs.m
//  Copyright © 2017 Devhouse Spindle. All rights reserved.
//

#import "VSLCodecs.h"
#import "VSLLogging.h"

@interface VSLCodecs()

@property (readwrite, nonatomic) NSUInteger priority;
@property (readwrite, nonatomic) VSLCodec codec;

@end

@implementation VSLCodecs

- (instancetype)initWithCodec:(VSLCodec)codec andPriotity:(NSUInteger)priority {
    if (self = [super init]) {
        self.priority = priority;
        self.codec = codec;
    }
    return self;
}

@end
