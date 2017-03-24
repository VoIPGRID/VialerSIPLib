//
//  VSLCodecs.m
//  Copyright © 2017 Devhouse Spindle. All rights reserved.
//

#import "VSLCodecs.h"
#import "VSLEndpoint.h"
#import "VSLLogging.h"
#import "NSString+PJString.h"

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

+ (BOOL)updateCodecs:(NSArray *)codecsToUse {
    if ([VSLEndpoint sharedEndpoint].state != VSLEndpointStarted || [codecsToUse count] > 1) {
        return NO;
    }
    
    const unsigned codecInfoSize = 64;
    pjsua_codec_info codecInfo[codecInfoSize];
    unsigned codecCount = codecInfoSize;
    pj_status_t status = pjsua_enum_codecs(codecInfo, &codecCount);
    if (status != PJ_SUCCESS) {
        VSLLogError(@"Error getting list of codecs");
        return NO;
    } else {
        for (NSUInteger i = 0; i < codecCount; i++) {
            NSString *codecIdentifier = [NSString stringWithPJString:codecInfo[i].codec_id];
            pj_uint8_t priority = [self priorityForCodec:codecIdentifier forCodecs:codecsToUse];
            status = pjsua_codec_set_priority(&codecInfo[i].codec_id, priority);
            if (status != PJ_SUCCESS) {
                VSLLogError(@"Error setting codec priority to the correct value");
                return NO;
            }
        }
    }
    return YES;
}

+ (pj_uint8_t)priorityForCodec:(NSString *)identifier forCodecs:(NSArray *)codecsToUse {
    NSUInteger priority = 0;
    for (VSLCodecs* codecs in codecsToUse) {
        if ([VSLCodecString(codecs.codec) isEqualToString:identifier]) {
            priority = codecs.priority;
        }
    }
    return (pj_uint8_t)priority;
}

+ (NSString *)codecString:(VSLCodec)codec {
    return VSLCodecString(codec);
}

+ (NSString *)codecStringWithIndex:(NSInteger)index {
    return VSLCodecStringWithIndex(index);
}

+ (NSInteger)numberOfCodecs {
    return [VSLCodecsArray count];
}

+ (NSArray *)codecsArray {
    return VSLCodecsArray;
}

@end
