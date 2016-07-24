@import PromiseKit;
@import XCTest;
#import "Infrastructure.h"


@interface BridgingTests: XCTestCase @end @implementation BridgingTests

- (void)testChainAnyPromiseFromSwiftCode {
    XCTestExpectation *ex = [self expectationWithDescription:@""];
    AnyPromise *promise = PMKAfter(0.02);
    for (int x = 0; x < 100; ++x) {
        promise = promise.then(^{
            return [[[PromiseBridgeHelper alloc] init] bridge1];
        });
    }
    promise.then(^{
        [ex fulfill];
    });
    [self waitForExpectationsWithTimeout:20 handler:nil];
}

@end
