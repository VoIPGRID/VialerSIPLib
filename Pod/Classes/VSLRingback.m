//
//  VSLRingback.m
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import "VSLRingback.h"

#import <CocoaLumberjack/CocoaLumberjack.h>
#import <VialerPJSIP/pjsua.h>
#import "VSLEndpoint.h"
#import "NSString+PJString.h"

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

static int const VSLRingbackChannelCount = 1;
static int const VSLRingbackRingbackCount = 1;
static int const VSLRingbackFrequency1 = 440;
static int const VSLRingbackFrequency2 = 480;
static int const VSLRingbackOnDuration = 2000;
static int const VSLRingbackOffDuration = 4000;
static int const VSLRingbackInterval = 4000;

@interface VSLRingback()
@property (readonly, nonatomic) NSInteger ringbackSlot;
@property (readonly, nonatomic) pjmedia_port *ringbackPort;
@end

@implementation VSLRingback

-(instancetype)init {

    self = [super init];

    if (!self) {
        return nil;
    }

    VSLEndpoint *endpoint = [VSLEndpoint sharedEndpoint];

    pj_status_t status;
    pjmedia_tone_desc tone[VSLRingbackRingbackCount];
    pj_str_t name = pj_str("tone");

    //TODO make ptime and channel count not constant?

    NSUInteger samplesPerFrame = (PJSUA_DEFAULT_AUDIO_FRAME_PTIME * endpoint.endpointConfiguration.clockRate * VSLRingbackChannelCount) / 1000;

    status = pjmedia_tonegen_create2(endpoint.pjPool, &name, (unsigned int)endpoint.endpointConfiguration.clockRate, VSLRingbackChannelCount, (unsigned int)samplesPerFrame, 16, PJMEDIA_TONEGEN_LOOP, &_ringbackPort);

    if (status != PJ_SUCCESS) {
        DDLogDebug(@"Error creating ringback tones");
        return nil;
    }

    pj_bzero(&tone, sizeof(tone));

    for (int i = 0; i < VSLRingbackRingbackCount; ++i) {
        tone[i].freq1 = VSLRingbackFrequency1;
        tone[i].freq2 = VSLRingbackFrequency2;
        tone[i].on_msec = VSLRingbackOnDuration;
        tone[i].off_msec = VSLRingbackOffDuration;
    }

    tone[VSLRingbackRingbackCount - 1].off_msec = VSLRingbackInterval;

    pjmedia_tonegen_play(self.ringbackPort, VSLRingbackRingbackCount, tone, PJMEDIA_TONEGEN_LOOP);

    status = pjsua_conf_add_port(endpoint.pjPool, [self ringbackPort], (int *)&_ringbackSlot);

    if (status != PJ_SUCCESS) {
        DDLogDebug(@"Error adding media port for ringback tones");
        return nil;
    }
    return self;
}

-(void)dealloc {
    pjsua_conf_remove_port((int)self.ringbackSlot);
    pjmedia_port_destroy(self.ringbackPort);
}

-(void)start {
    if (!self.isPlaying) {
        pjsua_conf_connect((int)self.ringbackSlot, 0);
        self.isPlaying = YES;
    }
}

-(void)stop {
    if (self.isPlaying) {
        pjsua_conf_disconnect((int)self.ringbackSlot, 0);
        self.isPlaying = NO;
    }
}

@end
