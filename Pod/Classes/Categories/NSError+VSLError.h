//
//  NSString+PJString.m
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (VSLError)

/**
*  Creates and initializes an NSError object for a given domain and code.
*
*  It will also make an userInfo dictionary base on the param that are given (underlyingErrorKey, localizedDescriptionKey and localizedFailureReasonError).
*
*  @param underlyingErrorKey          The corresponding value is an error that was encountered in an underlying implementation and caused the error that the receiver represents to occur.
*  @param localizedDescriptionKey     The corresponding value is a localized string representation of the error that, if present, will be returned by localizedDescription.
*  @param localizedFailureReasonError The corresponding value is a localized string representation containing the reason for the failure that, if present, will be returned by localizedFailureReason.
*  @param errorDomain                 The error domain—this can be one of the predefined NSError domains, or an arbitrary string describing a custom domain. domain must not be nil. See Error Domains for a list of predefined domains.
*  @param errorCode                   The error code for the error.
*
*  @return NSError instance for domain with the specified error code and the dictionary of arbitrary data userInfo.
*/
+ (NSError * _Nonnull)VSLUnderlyingError:(NSError * _Nullable)underlyingErrorKey
                 localizedDescriptionKey:(NSString * _Nullable)localizedDescriptionKey
             localizedFailureReasonError:(NSString * _Nullable)localizedFailureReasonError
                             errorDomain:(NSString * _Nonnull)errorDomain
                               errorCode:(NSUInteger)errorCode;

@end
