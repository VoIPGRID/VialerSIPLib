//
//  VSLEndpointTests.m
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <VialerSIPLib-iOS/VSLAccount.h>
#import <VialerSIPLib-iOS/VSLEndpoint.h>
#import <VialerSIPLib-iOS/VSLEndpointConfiguration.h>

@interface VSLEndpointTests : XCTestCase
@property (strong, nonatomic) VSLEndpoint *endpoint;
@end

@implementation VSLEndpointTests

- (void)setUp {
    [super setUp];
    [VSLEndpoint resetSharedEndpoint];
    self.endpoint = [VSLEndpoint sharedEndpoint];
}

- (void)testEndpointHasOnDefaultNoAccounts {
    XCTAssertNotNil(self.endpoint.accounts, @"there should be an array");
    XCTAssertEqual([self.endpoint.accounts count], 0, @"There should be no accounts on default");
}

- (void)testEndpointWithAddedAccountShouldHaveTheAccount {
    VSLAccount *account = [[VSLAccount alloc] init];
    [self.endpoint addAccount:account];

    XCTAssertTrue([self.endpoint.accounts containsObject:account], @"The account should have been added to the array");
}

- (void)testCanRemoveAddedAccount {
    VSLAccount *account = [[VSLAccount alloc] init];
    [self.endpoint addAccount:account];
    [self.endpoint removeAccount:account];

    XCTAssertFalse([self.endpoint.accounts containsObject:account], @"The account should have been removed from the array");
}

- (void)testThatResetWillCreateNewEndpoint {
    // Bit of a hack, but it is a way to check
    VSLAccount *account = [[VSLAccount alloc] init];
    [self.endpoint addAccount:account];
    NSArray *previousAccounts = self.endpoint.accounts;

    [VSLEndpoint resetSharedEndpoint];

    XCTAssertNotEqual([VSLEndpoint sharedEndpoint].accounts, previousAccounts);
}

- (void)testCanAddConfigurationToEndpoint {
    VSLEndpointConfiguration *config = [[VSLEndpointConfiguration alloc] init];
    [self.endpoint configureWithEndpointConfiguration:config withCompletion:^(NSError * _Nullable error) {
        XCTAssertNil(error, @"There should be no error");
        XCTAssertEqual(self.endpoint.endpointConfiguration, config, @"The config should have been stored");
    }];
}

@end
