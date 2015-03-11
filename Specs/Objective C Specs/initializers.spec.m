@import XCTest;
#import "PromiseKit/Promise.h"

enum InitializersTestCaseEnum {
    PMKPromiseWrapTestCaseEnum1,
    PMKPromiseWrapTestCaseEnum2
};

@interface InitializersTestCase: XCTestCase @end @implementation InitializersTestCase

- (void)mock1:(BOOL)error :(void(^)(id, id))handler {
    dispatch_async(dispatch_get_main_queue(), ^{
        handler(error ? nil : @1, error ? [NSError new] : nil);
    });
}

- (void)mock2:(void(^)(enum InitializersTestCaseEnum, id))handler {
    dispatch_async(dispatch_get_main_queue(), ^{
        handler(1, nil);
    });
}


- (void)testAdapterFulfillment {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise promiseWithAdapter:^(PMKAdapter adapter) {
        [self mock1:NO:adapter];
    }].then(^(id result){
        XCTAssertEqualObjects(result, @1);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testAdapterRejection {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise promiseWithAdapter:^(PMKAdapter adapter) {
        [self mock1:YES:adapter];
    }].then(^(id result){
        XCTFail();
    }).catch(^{
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

@end
