//
//  SipUser.h
//  VialerSIPLib
//
//  Created by Redmer Loen on 17-12-15.
//  Copyright © 2015 Harold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VialerSIPLib-iOS/VialerSIPLib.h>

@interface SipUser : NSObject <SIPEnabledUser>

@property (strong, nonatomic) NSString *sipUsername;
@property (strong, nonatomic) NSString *sipPassword;
@property (strong, nonatomic) NSString *sipDomain;
@property (strong, nonatomic) NSString *sipProxy;
@property (nonatomic) BOOL sipRegisterOnAdd;

@end
