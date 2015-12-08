//
//  VSLAccountConfiguration.h
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VSLAccountConfiguration : NSObject

@property (strong, nonnull, nonatomic) NSString *sipUsername;
@property (strong, nonnull, nonatomic) NSString *sipPassword;
@property (strong, nonnull, nonatomic) NSString *sipDomain;
@property (strong, nonnull, nonatomic) NSString *sipProxyServer;
@property (strong, nonnull, nonatomic) NSString *sipAddress;
@property (strong, nonnull, nonatomic) NSString *sipAuthRealm;
@property (strong, nonnull, nonatomic) NSString *sipAuthScheme;
@property (nonatomic) BOOL sipRegisterOnAdd;
@property (nonatomic) BOOL sipPublishEnabled;

@end
