//
//  NSString+PJString.m
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import "NSString+PJString.h"

@implementation NSString (PJString)

- (pj_str_t)pjString {
    return pj_str((char *)[self cStringUsingEncoding:NSUTF8StringEncoding]);
}

+ (NSString *)stringWithPJString:(pj_str_t)pjString {
    return [[NSString alloc] initWithBytes:pjString.ptr length:(NSUInteger)pjString.slen encoding:NSUTF8StringEncoding];
}

- (NSString *)prependSipUri {
    NSString *sipUri = self;

    if (![sipUri hasPrefix:@"sip:"]) {
        sipUri = [NSString stringWithFormat:@"sip:%@", sipUri];
    }

    return sipUri;
}

- (pj_str_t)sipUriWithDomain:(NSString *)domain {
    NSString *sipUri = [self prependSipUri];

    if ([sipUri rangeOfString:@"@"].location == NSNotFound) {
        sipUri = [NSString stringWithFormat:@"%@@%@", sipUri, domain];
    }

    if (![sipUri hasSuffix:domain]) {
        sipUri = [sipUri stringByPaddingToLength:[sipUri rangeOfString:@"@"].location withString:@"" startingAtIndex:0];
        sipUri = [NSString stringWithFormat:@"%@@%@", sipUri, domain];
    }
    return sipUri.pjString;
}

@end
