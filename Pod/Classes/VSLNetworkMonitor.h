//
//  VSLNetworkMonitor.h
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Notification that will be posted when an IP address change is detected.
 */
extern NSString * _Nonnull const VSLNetworkMonitorChangedNotification;

@interface VSLNetworkMonitor : NSObject

/**
 *  Create a monitoring class that will notify when the internet connection has changed.
 *
 *  @param host NSString with the host that should be checked for reachability.
 *
 *  @return VSLNetworkMonitor instance.
 */
- (VSLNetworkMonitor * _Nullable)initWithHost:(NSString *_Nonnull)host;

/**
 *  This will start the monitoring of the IP address.
 */
- (void)startMonitoring;

/**
 *  This will stop the monitoring of the IP address.
 */
- (void)stopMonitoring;

@end
