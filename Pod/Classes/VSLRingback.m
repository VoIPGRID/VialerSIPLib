//
//  VSLRingback.m
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import "VSLRingback.h"

#import "Constants.h"
#import "NSString+PJString.h"
#import <VialerPJSIP/pjsua.h>
#import "VSLEndpoint.h"
#import "VSLLogging.h"

static int const VSLRingbackChannelCount = 1;
static int const VSLRingbackRingbackCount = 1;
static int const VSLRingbackFrequency1 = 440;
static int const VSLRingbackFrequency2 = 440;
static int const VSLRingbackOnDuration = 2000;
static int const VSLRingbackOffDuration = 4000;
static int const VSLRingbackInterval = 4000;

@interface VSLRingback()
@property (readonly, nonatomic) NSInteger ringbackSlot;
@property (readonly, nonatomic) pjmedia_port *ringbackPort;
@end

@implementation VSLRingback

-(instancetype)init {
    if (!(self = [super init])) {
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
        char statusmsg[PJ_ERR_MSG_SIZE];
        pj_strerror(status, statusmsg, sizeof(statusmsg));
        VSLLogDebug(@"Error creating ringback tones, status: %s", statusmsg);
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
        char statusmsg[PJ_ERR_MSG_SIZE];
        pj_strerror(status, statusmsg, sizeof(statusmsg));
        VSLLogDebug(@"Error adding media port for ringback tones, status: %s", statusmsg);
        return nil;
    }
    return self;
}

-(void)dealloc {
    [self checkCurrentThreadIsRegisteredWithPJSUA];
    // Destory the conference port otherwise the maximum number of ports will reached and pjsip will crash.
    pj_status_t status = pjsua_conf_remove_port((int)self.ringbackSlot);
    if (status != PJ_SUCCESS) {
        char statusmsg[PJ_ERR_MSG_SIZE];
        pj_strerror(status, statusmsg, sizeof(statusmsg));
        VSLLogWarning(@"Error removing the port, status: %s", statusmsg);
        return;
    }
    
    pjmedia_port_destroy(self.ringbackPort);
}

-(void)start {
    VSLLogInfo(@"Start ringback, isPlaying: %@", self.isPlaying ? @"YES" : @"NO");
    if (!self.isPlaying) {
        pjsua_conf_connect((int)self.ringbackSlot, 0);
        self.isPlaying = YES;
    }
}

-(void)stop {
    VSLLogInfo(@"Stop ringback, isPlaying: %@", self.isPlaying ? @"YES" : @"NO");
    if (self.isPlaying) {
        pjsua_conf_disconnect((int)self.ringbackSlot, 0);
        self.isPlaying = NO;

        // Destory the conference port otherwise the maximum number of ports will reached and pjsip will crash.
        pj_status_t status = pjsua_conf_remove_port((int)self.ringbackSlot);
        if (status != PJ_SUCCESS) {
            char statusmsg[PJ_ERR_MSG_SIZE];
            pj_strerror(status, statusmsg, sizeof(statusmsg));
            VSLLogWarning(@"Error removing the port, status: %s", statusmsg);
        }
    }
}

- (void)checkCurrentThreadIsRegisteredWithPJSUA {
    static pj_thread_desc a_thread_desc;
    static pj_thread_t *a_thread;
    if (!pj_thread_is_registered()) {
        pj_thread_register("VialerPJSIP", a_thread_desc, &a_thread);
    }
}
@end
