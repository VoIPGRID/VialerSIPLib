//
//  VSLVideoCodecs.h
//  VialerSIPLib
//
//  Created by Redmer Loen on 4/5/18.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, VSLVideoCodec) {
        // H264
    VSLVideoCodecH264
};
#define VSLVideoCodecString(VSLVideoCodec) [VSLVideoCodecArray objectAtIndex:VSLVideoCodec]
#define VSLVideoCodecStringWithIndex(NSInteger) [VSLVideoCodecArray objectAtIndex:NSInteger]
#define VSLVideoCodecArray @[@"H264/97"]


@interface VSLVideoCodecs : NSObject

/**
 *  The prioritiy of the codec
 */
@property (readonly, nonatomic) NSUInteger priority;

/**
 * The used codec.
 */
@property (readonly, nonatomic) VSLVideoCodec codec;

/**
 * Make the default init unavaibale.
 */
- (instancetype _Nonnull) init __attribute__((unavailable("init not available. Use initWithVideoCodec instead.")));

/**
 * The init to setup the video codecs.
 *
 * @param codec     Audio codec codec to set the prioritiy for.
 * @param priority  NSUInteger the priority the codec will have.
 */
- (instancetype _Nonnull)initWithVideoCodec:(VSLVideoCodec)codec andPriority:(NSUInteger)priority;

/**
 * Get the codec from the #define VSLVideoCodecString with a VSLVideoCodec type.
 *
 * @param codec VSLVideoCodec the codec to get the string representation of.
 *
 * @return NSString the string representation of the VSLVideoCodec type.
 */
+ (NSString * _Nonnull)codecString:(VSLVideoCodec)codec;

/**
 * Get the codec from the defined VSLVideoCodecString with an index.
 */
+ (NSString * _Nonnull)codecStringWithIndex:(NSInteger)index;

@end
