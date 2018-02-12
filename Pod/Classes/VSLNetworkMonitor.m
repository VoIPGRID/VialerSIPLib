//
//  VSLNetworkMonitor.m
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import "VSLNetworkMonitor.h"

#import "Constants.h"
#import "Reachability.h"
#import "VSLLogging.h"


static double const VSLNetworkMonitorDelayTimeForNotification = 1;

NSString * const VSLNetworkMonitorChangedNotification = @"VSLNetworkMonitorChangedNotification";

@interface VSLNetworkMonitor()

@property (strong, nonatomic) NSString *host;
@property (strong, nonatomic) Reachability *networkMonitor;
@property (nonatomic) BOOL isChangingNetwork;

@end

@implementation VSLNetworkMonitor

- (VSLNetworkMonitor *)initWithHost:(NSString *)host {
    if (self = [super init]) {
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
    [self.networkMonitor startNotifier];
    // Delay the registering of the notification to ignore the initial reachability changed notifications.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(VSLNetworkMonitorDelayTimeForNotification * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged:) name:kReachabilityChangedNotification object:nil];
    });
}

- (void)stopMonitoring {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [self.networkMonitor stopNotifier];
    self.networkMonitor = nil;
}

#pragma mark - Notifications

- (void)internetConnectionChanged:(NSNotification *)notification {
    /**
     *  Don't respond immediately to every network change. Because network changes will happen rapidly and go back an forth
     *  a couple of times, wait a little before posting the notification.
     */
    VSLLogDebug(@"Internet connection changed");

    if (self.isChangingNetwork) {
        return;
    }
    self.isChangingNetwork = YES;

    __weak VSLNetworkMonitor *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(VSLNetworkMonitorDelayTimeForNotification * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        VSLLogInfo(@"Posting notification that internet connection has changed.");
        weakSelf.isChangingNetwork = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:VSLNetworkMonitorChangedNotification object:nil];
    });
}

@end
