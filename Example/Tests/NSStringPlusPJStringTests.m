//
//  TestsNSString.m
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <VialerSIPLib/NSString+PJString.h>

@interface NSStringPlusPJStringTests : XCTestCase

@end

@implementation NSStringPlusPJStringTests

- (void)testPrependSipUri {
    // Given
    NSString *string = @"StringToCheck";
    // When
    string = [string prependSipUri];
    // Then
    XCTAssertEqualObjects(string, @"sip:StringToCheck", @"String did not append sip:");
}

@end
