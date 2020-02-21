//
//  VSLCallStats.m
//  Copyright © 2017 Devhouse Spindle. All rights reserved.
//

#import "VSLCallStats.h"

#import "NSString+PJString.h"
#import "VSLCall.h"
#import "VSLLogging.h"
#import "VialerSIPLib.h"

static NSString * const VSLCallStatsCodecImpairments = @"CodecImpairment";
static NSString * const VSLCallStatsBPL = @"BPL";
static NSString * const VSLCallStatsCodecFrameSize = @"CodecFrameSize";
NSString * const VSLCallStatsMOS = @"VSLCallStatsMOS";
NSString * const VSLCallStatsActiveCodec = @"VSLCallStatsActiveCodec";
NSString * const VSLCallStatsTotalMBsUsed = @"VSLCallStatsTotalMBsUsed";


@interface VSLCallStats()
@property (readwrite, nonatomic) NSString *activeCodec;
@property (readwrite, nonatomic) float totalMBsUsed;
@property (readwrite, nonatomic) float MOS;

@property (nonatomic) int framePackingTime;
@property (nonatomic) NSDictionary* codecSettings;
@property (weak, nonatomic) VSLCall* call;

/**
 * Send loudness rating (dB)
 */
@property (nonatomic) float SLR;

/**
 * Receive loudness rating (dB)
 */
@property (nonatomic) float RLR;

/**
 * Sidetone masking rating (dB)
 */
@property (nonatomic) float STMR;

/**
 * Listener sidetone rating (dB)
 */
@property (nonatomic) float LSTR;

/**
 * D-Value of telephone, send side
 */
@property (nonatomic) float Ds;

/**
 * D-Value of telephone, receiver side
 */
@property (nonatomic) float Dr;

/**
 * Talker echo loudness rating (ms)
 */
@property (nonatomic) float TELR;

/**
 * Weighted echo path loss (ms)
 */
@property (nonatomic) float WEPL;

/**
 * Mean one-way delay of the echo path (ms)
 */
@property (nonatomic) float T;

/**
 * Round-trip delay in a 4-wire loop (ms)
 */
@property (nonatomic) float Tr;

/**
 * Absolute delay in echo-free connections (ms)
 */
@property (nonatomic) float Ta;

/**
 * Delay sensitivity
 */
@property (nonatomic) float sT;

/**
 * Minimum pereivable delay (ms)
 */
@property (nonatomic) float mT;

/**
 * Number of quantization distortion units
 */
@property (nonatomic) float qdu;

/**
 * Circuit noise referred to 0 dBr-point (dBm0p)
 */
@property (nonatomic) float Nc;

/**
 * Noise floor at the receive side (dBm0p)
 */
@property (nonatomic) float Nfor;

/**
 * Room noise at the send side (db(A))
 */
@property (nonatomic) float Ps;

/**
 * Room noise at the receive side (db(A))
 */
@property (nonatomic) float Pr;

/**
 * Basic signal-to-noise ratio.
 */
@property (nonatomic) float Ro;

@property (nonatomic) float OLR;

@property (nonatomic) float Ist;

@property (nonatomic) float No;

@property (nonatomic) pjsua_stream_info streamInfo;

@property (nonatomic) pjsua_stream_stat streamStat;
@end

@implementation VSLCallStats

#pragma mark - Life Cycle

-(instancetype)initWithCall:(VSLCall *)call {
    if (self = [super init]) {
        self.call = call;
        
        // Some static codec specific values.
        self.codecSettings = @{
                               @"PCMA": @{
                                       VSLCallStatsCodecImpairments: @0.0,
                                       VSLCallStatsBPL: @4.3,
                                       VSLCallStatsCodecFrameSize: @0.125
                                       },
                               @"PCMU": @{
                                       VSLCallStatsCodecImpairments: @0.0,
                                       VSLCallStatsBPL: @4.3,
                                       VSLCallStatsCodecFrameSize: @0.125
                                       },
                               @"G722": @{
                                       VSLCallStatsCodecImpairments: @0.0,
                                       VSLCallStatsBPL: @4.3,
                                       VSLCallStatsCodecFrameSize: @4.0
                                       },
                               @"iLBC": @{
                                       VSLCallStatsCodecImpairments: @32.0,
                                       VSLCallStatsBPL: @50.0,
                                       VSLCallStatsCodecFrameSize: @25.0
                                       },
                               @"Speex": @{
                                       VSLCallStatsCodecImpairments: @18.0,
                                       VSLCallStatsBPL: @21.0,
                                       VSLCallStatsCodecFrameSize: @30.0
                                       },
                               @"GSM": @{
                                       VSLCallStatsCodecImpairments: @28.0,
                                       VSLCallStatsBPL: @34.0,
                                       VSLCallStatsCodecFrameSize: @25.0
                                       },
                               @"opus": @{
                                       VSLCallStatsCodecImpairments: @11.0,
                                       VSLCallStatsBPL: @12.0,
                                       VSLCallStatsCodecFrameSize: @20.0
                                       },
                               };

        //Sane default values based on ITU document G.107.
        self.SLR     = 8;
        self.RLR     = 2;
        self.STMR    = 15;
        self.LSTR    = 18;
        self.Ds      = 3;
        self.Dr      = 3;
        self.TELR    = 65;
        self.WEPL    = 110;
        self.T       = 0;
        self.Tr      = 0;
        self.Ta      = 0;
        self.sT      = 1;
        self.mT      = 100;
        self.qdu     = 1;
        self.Nc      = -70;
        self.Nfor    = -64;
        self.Ps      = 35;
        self.Pr      = 35;
        
        self.LSTR = self.Dr + self.STMR;
        self.OLR = self.SLR + self.RLR;
    }
    return self;
}

# pragma mark - Actions

- (NSDictionary *)generate{
    NSDictionary *stats = @{};

    pjsua_call_info callInfo;
    pjsua_call_get_info((pjsua_call_id)self.call.callId, &callInfo);

    if (callInfo.media_status != PJSUA_CALL_MEDIA_ACTIVE) {
        VSLLogDebug(@"Stream is not active!");
        return stats;
    }
    
    pj_status_t status;
    pjsua_stream_info stream_info;
    status = pjsua_call_get_stream_info((pjsua_call_id)self.call.callId, callInfo.media[0].index, &stream_info);

    if (status == PJ_SUCCESS) {
        self.streamInfo = stream_info;
        [self codecUsed];
        
        pj_status_t status;
        pjsua_stream_stat stream_stat;
        status = pjsua_call_get_stream_stat((pjsua_call_id)self.call.callId, callInfo.media[0].index, &stream_stat);
        
        if (status == PJ_SUCCESS) {
            self.streamStat = stream_stat;
            [self getCodecValues];
            [self calculateMOS];
            [self calculateTotalMBsUsed];
            
            stats = @{
                      VSLCallStatsMOS: [[NSNumber alloc] initWithFloat:self.MOS],
                      VSLCallStatsActiveCodec: self.activeCodec,
                      VSLCallStatsTotalMBsUsed: [[NSNumber alloc] initWithFloat:self.totalMBsUsed]
                      };
        } else {
            VSLLogDebug(@"Unknown stream stat found");
            self.MOS = 0;
        }
    } else {
        char statusmsg[PJ_ERR_MSG_SIZE];
        pj_strerror(status, statusmsg, sizeof(statusmsg));
        VSLLogDebug(@"No stream found, status: %s", statusmsg);

        self.activeCodec = @"Unknown";
    }
    
    return stats;
}

- (void)codecUsed {
    if (self.streamInfo.type == PJMEDIA_TYPE_AUDIO) {
        pj_str_t active_codec = self.streamInfo.info.aud.fmt.encoding_name;
        self.activeCodec = [NSString stringWithPJString:active_codec];
        self.framePackingTime = (int)self.streamInfo.info.aud.param->info.frm_ptime;
    } else {
        VSLLogDebug(@"Stream is not an audio stream");
        self.activeCodec = @"Unknown";
    }
}

- (void)calculateTotalMBsUsed {
    self.totalMBsUsed = (self.streamStat.rtcp.rx.bytes + self.streamStat.rtcp.tx.bytes) / 1024.0 / 1024.0;
}

/**
 * Calculate MOS value for the call.
 */
- (void)calculateMOS {
    float Ro = [self calculateSignalToNoiseRatio];
    float Is = [self calculateSimultaneousImpariments];
    float Id = [self calculateDelayImpairmentFactor];
    float Ie = [self calculateEquipmentImpairment];
    
    float R = Ro - Is - Id - Ie;
    
    VSLLogDebug(@"R: %f", R);

    if (R > 100) {
        self.MOS = 4.5f;
    } else {
        if (R > 0) {
            self.MOS = 1 + R * 0.035f + R * (R - 60.0f) * (100.0f - R) * 7.0f * pow(10.0f, -6.0f);
        } else {
            self.MOS = 0.0f;
            VSLLogDebug(@"No MOS");
        }
    }
}

#pragma mark - MOS calculations

/**
 * Calculate the simultaneous impairment factor, Is.
 *
 * This is the sum of all impairments which may occur more or less 
 * simultaneously with the voice transmission.
 */
- (float)calculateSimultaneousImpariments {
    float Q;
    if (self.qdu < 1.0f) {
        Q = 37.0f - 15.0f * log10f(1.0f) / log10f(10.0f);
    } else {
        Q = 37.0f - 15.0f * log10f(self.qdu) / log10f(10.0f);
    }
    float G = 1.07f + 0.258f * Q + 0.0602f * pow(Q, 2);
    float Z = 46.0f / 30.0f - G / 40.0f;
    float Y = (self.Ro - 100.0f) / 15.0f + 46.0f / 8.4f - G / 9.0f;
    float Iq = 15.0f * log10f(1 + pow(10, Y) + pow(10, Z));
    float STMRo = -10 * log10f(pow(10, -self.STMR / 10.0f) + exp(-self.T / 4.0f) * pow(10, -self.TELR / 10.0f));
    self.Ist = 12 * pow( 1 + pow( (STMRo - 13.0f) / 6.0f, 8), 1.0f / 8.0f) -28 * pow( 1 + pow( (STMRo + 1) / 19.4f, 35), 1.0f / 35.0f) -13 * pow( 1 + pow( (STMRo - 3) / 33.0f, 13), 1.0f / 13.0f) + 29;
    float Xolr = self.OLR + 0.2f * (64.0f + self.No - self.RLR);
    float Iolr = 20 * (pow( 1 + pow(Xolr / 8.0f, 8.0f), 1.0f / 8.0f) - Xolr / 8);
    
    float Is = Iolr + self.Ist + Iq;
    
    return Is;
}

/**
 * Calculate the signal to noise radio, Ro.
 */
- (float)calculateSignalToNoiseRatio {
    float Nfo = self.Nfor + self.RLR;
    
    float Nos = self.Ps - self.SLR - self.Ds - 100.0f + 0.004f * pow((self.Ps - self.OLR - self.Ds - 14.0f), 2.0f);
    float Pre = self.Pr + 10 * log10f(1.0f + pow(10.0f, ((10.0f - self.LSTR) / 10.0f)))/log10f(10.0f);
    float Nor = self.RLR - 121.0f + Pre + 0.008f * pow(Pre - 35.0f, 2.0f);
    self.No = 10 * log10f(
                           pow(10, (self.Nc / 10.0f)) +
                           pow(10, (Nos / 10.0f)) +
                           pow(10, (Nor / 10.0f)) +
                           pow(10, (Nfo / 10.0f))
                           );
    self.Ro = 15.0f - 1.5f * (self.SLR + self.No);
    
    return self.Ro;
}

/**
 * Calculate the delay impairment factor, Id.
 *
 * Representing all the impairments due to delay of voice signals.
 */
- (float)calculateDelayImpairmentFactor {
    float Rle = 10.5 * (self.WEPL + 7) * pow(self.Tr + 1, -0.25);
    float X;
    if (self.Ta == 0.0f) {
        X = 0.0f;
    } else {
        X = (log10f(self.Ta / 100.0f)) / (log10f(2));
    }
    
    float Idd;
    if (self.Ta <= 100.0f) {
        Idd = 0.0f;
    } else {
        Idd = 25.0f * (pow(1.0f + pow(X, 6.0f), 1.0f / 6.0f ) -3.0f * pow(1.0f + pow(X / 3.0f, 6.0f), 1.0f / 6.0f) + 2.0f);
    }
    
    float Idle = (self.Ro - Rle) / 2.0f + sqrt((pow(self.Ro - Rle, 2.0f) / 4.0f) + 169);
    float TERV = self.TELR - 40.0f * log10f((1.0f + self.T / 10.0f) / (1.0f + self.T / 150.0f)) + 6.0f * exp( -0.3f * pow(self.T, 2));
    float TERVs = TERV + (self.Ist / 2);
    float Roe = -1.5 * (self.No - self.RLR);
    
    float Re;
    if (self.STMR < 9.0f) {
        Re = 80 + 2.5 * (TERVs - 14);
    } else {
        Re = 80 + 2.5 * (TERV - 14);
    }
    
    float Idte;
    
    if (self.T < 1.0f) {
        Idte = 0.0f;
    } else {
        Idte = ((Roe - Re) / 2.0f + sqrt(pow(Roe - Re, 2) / 4.0f + 100.0f) - 1.0f) * (1.0f - exp(-self.T));
    }
    
    float Id;
    if (self.STMR > 20.0f) {
        float Idtes = sqrt((pow(Idte, 2)) + (pow(self.Ist, 2)));
        Id = Idtes + Idle + Idd;
    } else {
        Id = Idte + Idle + Idd;
    }
    
    return Id;
}

/**
 * Calculate the equipment impariment factor, Ie.
 */
- (float)calculateEquipmentImpairment {
    NSNumber *codecImpairmentValue = [[self.codecSettings objectForKey:self.activeCodec] objectForKey:VSLCallStatsCodecImpairments];
    NSNumber *bplValue = [[self.codecSettings objectForKey:self.activeCodec] objectForKey:VSLCallStatsBPL];

    float codecImpairment = codecImpairmentValue.floatValue;
    float bpl = bplValue.floatValue;
    float burstR = self.streamStat.jbuf.avg_burst;
    float rxPackets = self.streamStat.rtcp.rx.pkt;
    float txPackets = self.streamStat.rtcp.tx.pkt;
    float rxPacketLoss = self.streamStat.rtcp.rx.loss;
    float txPacketLoss = self.streamStat.rtcp.tx.loss;
    float rxPacketLossPercentage = rxPackets == 0 ? 100.0 : (rxPacketLoss / rxPackets) * 100.0f;
    float txPacketLossPercentage = txPackets == 0 ? 100.0 : (txPacketLoss / txPackets) * 100.0f;
    float ppl = (rxPacketLossPercentage + txPacketLossPercentage) / 2;
    float Ie = codecImpairment + (95 - codecImpairment) * (ppl / (ppl / burstR + bpl));
    
    return Ie;
}

/**
 * Calculate the the values for:
 * - Mean one-way delay of the echo path (T)
 * - Round-trip dealy in a 4-wire loop (Tr)
 * - Absolute dealy in echo-free connections (Ts)
 *
 * Based on the The Prognosis model
 */
- (void)getCodecValues {
    NSNumber *frameSizeValue = [[self.codecSettings objectForKey:self.activeCodec] objectForKey:VSLCallStatsCodecFrameSize];
    
    float packetSize = self.framePackingTime;
    float frameSize = frameSizeValue.floatValue;
    float codecVariant = 5;
    float jitter = self.streamStat.rtcp.rx.jitter.fmean_ / 1000.0f + self.streamStat.rtcp.tx.jitter.fmean_ / 1000.0f;
    
    float Towtd = self.streamStat.rtcp.rtt.fmean_ / 1000.0f / 2.0f;
    float Tenc = (packetSize + 0.2f * frameSize) + codecVariant;
    float Tdec = frameSize + jitter;
    
    self.T = Tenc + Towtd + Tdec;
    self.Tr = Tenc + 2 * Towtd + Tdec;
    self.Ta = Tenc + Towtd + Tdec;
    
    VSLLogDebug(@"T: %f - Tr: %f - Ta: %f", self.T, self.Tr, self.Ta);
}

@end
