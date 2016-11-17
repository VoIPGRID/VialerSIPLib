//
//  VSLClassTests.m
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import <VialerSIPLib/VSLAccount.h>
#import <VialerSIPLib/VSLCall.h>

@interface VSLCall()
- (NSDictionary * _Nonnull)getCallerInfoFromRemoteUri:(NSString * _Nonnull)string;
@end

@interface VSLCallTests : XCTestCase
@property (strong, nonatomic) id accountMock;
@end

@implementation VSLCallTests

- (void)setUp {
    [super setUp];
    self.accountMock = OCMStrictClassMock([VSLAccount class]);
}

- (void)tearDown {
    [self.accountMock stopMocking];
    self.accountMock = nil;
    [super tearDown];
}

- (void)testCallerNameCallerNumberOne {
    NSString *inputString = @"\"test\" <sip:42@test.nl>";

    VSLCall *call = [[VSLCall alloc] initInboundCallWithCallId:0 account:self.accountMock];
    NSDictionary *dictionary = [call getCallerInfoFromRemoteUri:inputString];

    XCTAssert([dictionary[@"caller_name"] isEqualToString:@"test"], @"The caller_name needs to be test");
    XCTAssert([dictionary[@"caller_number"] isEqualToString:@"42"], @"The caller_number needs to be 42");
}

- (void)testCallerNameCallerNumberTwo {
    NSString *inputString = @"sip:42@test.nl (test)";

    VSLCall *call = [[VSLCall alloc] initInboundCallWithCallId:0 account:self.accountMock];
    NSDictionary *dictionary = [call getCallerInfoFromRemoteUri:inputString];

    XCTAssert([dictionary[@"caller_name"] isEqualToString:@"test"], @"The caller_name needs to be test");
    XCTAssert([dictionary[@"caller_number"] isEqualToString:@"42"], @"The caller_number needs to be 42");
}

- (void)testCallerNameNoDisplayNameInRemoteURI {
    NSString *inputString = @"<sip:42@test.nl>";

    VSLCall *call = [[VSLCall alloc] initInboundCallWithCallId:0 account:self.accountMock];
    NSDictionary *dictionary = [call getCallerInfoFromRemoteUri:inputString];

    XCTAssert([dictionary[@"caller_name"] isEqualToString:@""], @"The caller_name needs to be empty");
    XCTAssert([dictionary[@"caller_number"] isEqualToString:@"42"], @"The caller_number needs to be 42");
}

- (void)testCallerNameNoDisplayNameInRemoteURITwo {
    NSString *inputString = @"sip:42@test.nl";

    VSLCall *call =[[VSLCall alloc] initInboundCallWithCallId:0 account:self.accountMock];
    NSDictionary *dictionary = [call getCallerInfoFromRemoteUri:inputString];

    XCTAssert([dictionary[@"caller_name"] isEqualToString:@""], @"The caller_name needs to be empty");
    XCTAssert([dictionary[@"caller_number"] isEqualToString:@"42"], @"The caller_number needs to be 42");
}

@end
