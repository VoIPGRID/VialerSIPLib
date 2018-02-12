//
//  VSLStunConfiguration.h
//  Copyright © 2018 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VSLStunConfiguration : NSObject

/**
 * Add the stun servers that are available to the NSArray.
 */
@property (strong, nonatomic) NSArray<NSString *> *stunServers;

/**
 * Property that will get the number of stun servers there are configured.
 */
@property (readonly, nonatomic) int numOfStunServers;

@end
