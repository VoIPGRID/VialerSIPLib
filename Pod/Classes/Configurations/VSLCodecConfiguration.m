//
//  VSLCodecConfiguration.m
//  Copyright © 2018 Devhouse Spindle. All rights reserved.


#import "VSLCodecConfiguration.h"

#import "NSString+PJString.h"

@implementation VSLCodecConfiguration

- (instancetype)init {
    if (self = [super init]) {
        self.audioCodecs = [self defaultAudioCodecs];
        self.videoCodecs = [self defaultVideoCodecs];
    }
    return self;
}

- (NSArray *) defaultAudioCodecs {
    return @[
            [[VSLAudioCodecs alloc] initWithAudioCodec:VSLAudioCodecG711a andPriority:210],
            [[VSLAudioCodecs alloc] initWithAudioCodec:VSLAudioCodecG722 andPriority:209],
            [[VSLAudioCodecs alloc] initWithAudioCodec:VSLAudioCodecILBC andPriority:208],
            [[VSLAudioCodecs alloc] initWithAudioCodec:VSLAudioCodecG711 andPriority:0],
            [[VSLAudioCodecs alloc] initWithAudioCodec:VSLAudioCodecSpeex8000 andPriority:0],
            [[VSLAudioCodecs alloc] initWithAudioCodec:VSLAudioCodecSpeex16000 andPriority:0],
            [[VSLAudioCodecs alloc] initWithAudioCodec:VSLAudioCodecSpeex32000 andPriority:0],
            [[VSLAudioCodecs alloc] initWithAudioCodec:VSLAudioCodecGSM andPriority:0],
            [[VSLAudioCodecs alloc] initWithAudioCodec:VSLAudioCodecOpus andPriority:0]
            ];
}

- (NSArray *) defaultVideoCodecs {
    return @[
             [[VSLVideoCodecs alloc] initWithVideoCodec:VSLVideoCodecH264 andPriority:210]
             ];
}

- (VSLOpusConfiguration *)opusConfiguration {
    if (!_opusConfiguration) {
        _opusConfiguration = [[VSLOpusConfiguration alloc] init];
    }
    return _opusConfiguration;
}

@end
