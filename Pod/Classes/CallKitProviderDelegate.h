//
//  CallKitProviderDelegate.h
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//
//

#import <Foundation/Foundation.h>

extern NSString * __nonnull const CallKitProviderDelegateOutboundCallStartedNotification;
extern NSString * __nonnull const CallKitProviderDelegateInboundCallAcceptedNotification;
extern NSString * __nonnull const CallKitProviderDelegateInboundCallRejectedNotification;

@import CallKit;

@class VSLCallManager, VSLCall;

@interface CallKitProviderDelegate : NSObject <CXProviderDelegate>

@property (strong, nonatomic) CXProvider *provider;

/**
 * This init is not available.
 */
-(instancetype _Nonnull) init __attribute__((unavailable("init not available")));

/**
 * Designated initializer
 *
 * @param callManager A instance of VSLCallManager.
 */
- (instancetype _Nonnull)initWithCallManager:(VSLCallManager * _Nonnull)callManager NS_DESIGNATED_INITIALIZER;

/**
 * Report the incoming call to CallKit so the native "incoming call" screen can be presented.
 *
 * @param call The incoming call
 */
- (void)reportIncomingCall:(VSLCall * _Nonnull)call;

@end
