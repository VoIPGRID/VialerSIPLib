//
//  IPAddress.m
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//  Code based on: http://stackoverflow.com/questions/7072989/iphone-ipad-osx-how-to-get-my-ip-address-programmatically
//

#import "IPAddressMonitor.h"

#include <arpa/inet.h>
#include <ifaddrs.h>
#include <net/if.h>
#import "Reachability.h"


static NSString * const IPAddressMonitorIOSCellular = @"pdp_ip0";
static NSString * const IPAddressMonitorIOSWifi = @"en0";
static NSString * const IPAddressMonitorIOSVPN = @"utun0";
static NSString * const IPAddressMonitorAddressIPv4 = @"ipv4";
static NSString * const IPAddressMonitorAddressIPv6 = @"ipv6";

NSString * const IPAddressMonitorChangedNotification = @"IPAddressMonitorChangedNotification";

@interface IPAddressMonitor()

@property (strong, nonatomic) NSString *host;
@property (strong, nonatomic) Reachability *networkMonitor;
@property (strong, nonatomic) NSString *currentIPAddress;

@end

@implementation IPAddressMonitor

- (IPAddressMonitor *)initWithHost:(NSString *)host {
    self = [super init];
    if (self) {
        self.host = host;
    }
    return self;
}

# pragma mark - Properties

- (Reachability *)networkMonitor {
    if (!_networkMonitor) {
        _networkMonitor = [Reachability reachabilityWithHostName:self.host];
    }
    return _networkMonitor;
}

#pragma mark - Actions

- (void)startMonitoring {
    self.currentIPAddress = [self getIPAddress:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged:) name:kReachabilityChangedNotification object:nil];
    [self.networkMonitor startNotifier];
}

- (void)stopMonitoring {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [self.networkMonitor stopNotifier];
    self.networkMonitor = nil;
}

#pragma mark - Notifications

- (void)internetConnectionChanged:(NSNotification *)notification {
    NSString *newIPAddress = [self getIPAddress:YES];
    if (![self.currentIPAddress isEqualToString:newIPAddress]) {
        self.currentIPAddress = newIPAddress;
        [[NSNotificationCenter defaultCenter] postNotificationName:IPAddressMonitorChangedNotification object:nil];
    }
}

#pragma mark - Utils

- (NSString *)getIPAddress:(BOOL)preferIPv4 {
    NSArray *searchArray = preferIPv4 ?
    @[ [NSString stringWithFormat:@"%@%@%@", IPAddressMonitorIOSVPN, @"/", IPAddressMonitorAddressIPv4],
       [NSString stringWithFormat:@"%@%@%@", IPAddressMonitorIOSVPN, @"/", IPAddressMonitorAddressIPv6],
       [NSString stringWithFormat:@"%@%@%@", IPAddressMonitorIOSWifi, @"/", IPAddressMonitorAddressIPv4],
       [NSString stringWithFormat:@"%@%@%@", IPAddressMonitorIOSWifi, @"/", IPAddressMonitorAddressIPv6],
       [NSString stringWithFormat:@"%@%@%@", IPAddressMonitorIOSCellular, @"/", IPAddressMonitorAddressIPv4],
       [NSString stringWithFormat:@"%@%@%@", IPAddressMonitorIOSCellular, @"/", IPAddressMonitorAddressIPv6]
       ] :
    @[ [NSString stringWithFormat:@"%@%@%@", IPAddressMonitorIOSVPN, @"/", IPAddressMonitorAddressIPv6],
       [NSString stringWithFormat:@"%@%@%@", IPAddressMonitorIOSVPN, @"/", IPAddressMonitorAddressIPv4],
       [NSString stringWithFormat:@"%@%@%@", IPAddressMonitorIOSWifi, @"/", IPAddressMonitorAddressIPv6],
       [NSString stringWithFormat:@"%@%@%@", IPAddressMonitorIOSWifi, @"/", IPAddressMonitorAddressIPv4],
       [NSString stringWithFormat:@"%@%@%@", IPAddressMonitorIOSCellular, @"/", IPAddressMonitorAddressIPv6],
       [NSString stringWithFormat:@"%@%@%@", IPAddressMonitorIOSCellular, @"/", IPAddressMonitorAddressIPv4]
       ] ;

    NSDictionary *addresses = [self getIPAddresses];

    __block NSString *address;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
         address = addresses[key];
         if (address) {
            *stop = YES;
         }
     }];
    return address ? address : @"0.0.0.0";
}

- (NSDictionary *)getIPAddresses {
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity: 8];

    // Retrieve the current interfaces - returns 0 on success.
    struct ifaddrs *interfaces;
    if (!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces.
        struct ifaddrs *interface;
        for (interface=interfaces; interface; interface=interface->ifa_next) {
            if (!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if (addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if (addr->sin_family == AF_INET) {
                    if (inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IPAddressMonitorAddressIPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;

                    if (inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IPAddressMonitorAddressIPv6;
                    }
                }
                if (type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}

@end
