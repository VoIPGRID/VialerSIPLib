//
//  VSLCodecs.m
//  Copyright © 2018 Devhouse Spindle. All rights reserved.
//

#import "VSLAudioCodecs.h"

@interface VSLAudioCodecs()
@property (readwrite, nonatomic) NSUInteger priority;
@property (readwrite, nonatomic) VSLAudioCodec codec;
@end

@implementation VSLAudioCodecs
- (instancetype)initWithAudioCodec:(VSLAudioCodec)codec andPriority:(NSUInteger)priority {
    if (self = [super init]) {
        self.codec = codec;
        self.priority = priority;
    }

    return self;
}

+ (NSString *)codecString:(VSLAudioCodec)codec {
    return VSLAudioCodecString(codec);
}

+ (NSString *)codecStringWithIndex:(NSInteger)index {
    return VSLAudioCodecStringWithIndex(index);
}
@end
