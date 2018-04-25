//
//  VSLVideoCodecs.m
//  VialerSIPLib
//
//  Created by Redmer Loen on 4/5/18.
//

#import "VSLVideoCodecs.h"

@interface VSLVideoCodecs()
@property (readwrite, nonatomic) NSUInteger priority;
@property (readwrite, nonatomic) VSLVideoCodec codec;
@end

@implementation VSLVideoCodecs
-(instancetype)initWithVideoCodec:(VSLVideoCodec)codec andPriority:(NSUInteger)priority {
    if (self = [super init]) {
        self.codec = codec;
        self.priority = priority;
    }
    return self;
}

+ (NSString *)codecString:(VSLVideoCodec)codec {
    return VSLVideoCodecString(codec);
}

+ (NSString *)codecStringWithIndex:(NSInteger)index {
    return VSLVideoCodecStringWithIndex(index);
}
@end
