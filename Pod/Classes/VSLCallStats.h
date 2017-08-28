//
//  VSLCallStats.h
//  Copyright © 2017 Devhouse Spindle. All rights reserved.
//

@class VSLCall;

/**
 * The key to get the MOS value from the call stats dictionairy.
 */
extern NSString * _Nonnull const VSLCallStatsMOS;

/**
 * The key to get the active codec from the call stats dictionairy.
 */
extern NSString * _Nonnull const VSLCallStatsActiveCodec;

/**
 * The key to get the total MBs used from the call stats dictionairy.
 */
extern NSString * _Nonnull const VSLCallStatsTotalMBsUsed;

@interface VSLCallStats : NSObject

/**
 *  Make the init unavailable.
 *
 *  @return compiler error.
 */
-(instancetype _Nonnull) init __attribute__((unavailable("init not available. Use initWithCall instead.")));

/**
 *  The init to set an own ringtone file.
 *
 *  @param call VSLCall object.
 *
 *  @return VSLCallStats instance.
 */
- (instancetype _Nullable)initWithCall:(VSLCall * _Nonnull)call NS_DESIGNATED_INITIALIZER;

/**
 * Generate the call status 
 * 
 * @return NSDictionary with following format:
 * @{
 *  VSLCallStatsMOS: NSNumber,
 *  VSLCallStatsActiveCodec: NSString,
 *  VSLCallStatsTotalMBsUsed: NSNumber
 * };
 */
- (NSDictionary * _Nullable)generate;

@end
