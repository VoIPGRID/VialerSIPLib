//
//  VSLClassTests.m
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import <VialerSIPLib-iOS/VSLCall.h>

@interface VSLCall()
- (NSDictionary * _Nonnull)getCallerInfoFromRemoteUri:(NSString * _Nonnull)string;
@end

@interface VSLCallTests : XCTestCase

@end

@implementation VSLCallTests

- (void)testCallerNameCallerNumberOne {
    NSString *inputString = @"\"test\" <sip:42@test.nl>";

    VSLCall *call = [[VSLCall alloc] init];
    NSDictionary *dictionary = [call getCallerInfoFromRemoteUri:inputString];

    XCTAssert([dictionary[@"caller_name"] isEqualToString:@"test"], @"The caller_name needs to be test");
    XCTAssert([dictionary[@"caller_number"] isEqualToString:@"42"], @"The caller_number needs to be 42");
}

- (void)testCallerNameCallerNumberTwo {
    NSString *inputString = @"sip:42@test.nl (test)";

    VSLCall *call = [[VSLCall alloc] init];
    NSDictionary *dictionary = [call getCallerInfoFromRemoteUri:inputString];

    XCTAssert([dictionary[@"caller_name"] isEqualToString:@"test"], @"The caller_name needs to be test");
    XCTAssert([dictionary[@"caller_number"] isEqualToString:@"42"], @"The caller_number needs to be 42");
}

- (void)testCallerNameNoDisplayNameInRemoteURI {
    NSString *inputString = @"<sip:42@test.nl>";

    VSLCall *call = [[VSLCall alloc] init];
    NSDictionary *dictionary = [call getCallerInfoFromRemoteUri:inputString];

    XCTAssert([dictionary[@"caller_name"] isEqualToString:@""], @"The caller_name needs to be empty");
    XCTAssert([dictionary[@"caller_number"] isEqualToString:@"42"], @"The caller_number needs to be 42");
}

- (void)testCallerNameNoDisplayNameInRemoteURITwo {
    NSString *inputString = @"sip:42@test.nl";

    VSLCall *call = [[VSLCall alloc] init];
    NSDictionary *dictionary = [call getCallerInfoFromRemoteUri:inputString];

    XCTAssert([dictionary[@"caller_name"] isEqualToString:@""], @"The caller_name needs to be empty");
    XCTAssert([dictionary[@"caller_number"] isEqualToString:@"42"], @"The caller_number needs to be 42");
}

@end
