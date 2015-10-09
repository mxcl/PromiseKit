#import <PromiseKit/PromiseKit.h>
@import XCTest;

__attribute__((objc_runtime_name("PMKPromiseBridgeHelper")))
__attribute__((objc_subclassing_restricted))
@interface PromiseBridgeHelper: NSObject
- (AnyPromise *)bridge1;
@end


@interface BridgingTestCase_ObjC: XCTestCase @end @implementation BridgingTestCase_ObjC

- (void)test1 {
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
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

@end


@implementation PromiseBridgeHelper (objc)

- (AnyPromise *)bridge2 {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            resolve(@123);
        });
    }];
}

@end
