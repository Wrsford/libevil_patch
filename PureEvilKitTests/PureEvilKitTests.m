//
//  PureEvilKitTests.m
//  PureEvilKitTests
//
//  Created by Will Stafford on 4/12/16.
//  Copyright © 2016 Landon Fuller. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <PureEvilKit/PureEvilKit.h>
@interface PureEvilKitTests : XCTestCase

@end

void myFunctionToPatch() {
	printf("Not patched");
}

void myPatch() {
	printf("Patched");
}

@implementation PureEvilKitTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPatch {
	void (*originalFunction)() = [PEManager overrideFunction:myFunctionToPatch newFunction:myPatch];
	
}

- (void)testUnpatchedPerformance {
	// This is an example of a performance test case.
	[self measureBlock:^{
		// Put the code you want to measure the time of here.
	}];
}

- (void)testPatchedPerformance {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
