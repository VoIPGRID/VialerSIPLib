//
//  IPAddress.h
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//  Code based on: http://stackoverflow.com/questions/7072989/iphone-ipad-osx-how-to-get-my-ip-address-programmatically
//

#import <Foundation/Foundation.h>

/**
 *  Notification that will be posted when an IP address change is detected.
 */
extern NSString * _Nonnull const IPAddressMonitorChangedNotification;

@interface IPAddressMonitor : NSObject

/**
 *  Create a monitoring class that will notify when the external IP has changed.
 *
 *  @param host NSString with the host that should be checked for reachability.
 *
 *  @return IPAddressMonitor instance.
 */
- (IPAddressMonitor * _Nullable)initWithHost:(NSString *_Nonnull)host;

/**
 *  This will start the monitoring of the IP address.
 */
- (void)startMonitoring;

/**
 *  This will stop the monitoring of the IP address.
 */
- (void)stopMonitoring;

@end
