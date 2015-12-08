//
//  NSString+PJString.m
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

#import "NSString+PJString.h"

@implementation NSString (PJString)

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

- (pj_str_t)pjString {
    return pj_str((char *)[self cStringUsingEncoding:NSUTF8StringEncoding]);
}

@end
