//
//  NSString+PJString.h
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <VialerPJSIP/pjsua.h>
#import "VSLAccount.h"

@interface NSString (PJString)

/**
 This will return a string which can be read by human eyes.
 */
+ (NSString *)stringWithPJString:(pj_str_t)pjString;

/**
 This will prepend "sip:" in front of the string.
 */
- (NSString *)prependSipUri;

/**
 This will create a sip uri with added domain info if necessary.

 @param domain a string with domain info.
 */
- (pj_str_t)sipUriWithDomain:(NSString *)domain;

/**
 This returns a string for the pjsip library.
 */
@property (readonly) pj_str_t pjString;

@end
