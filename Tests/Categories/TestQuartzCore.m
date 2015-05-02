#import "CALayer+AnyPromise.h"
@import QuartzCore;
@import XCTest;


@interface TestCALayer: XCTestCase @end @implementation TestCALayer

- (void)test {
    id ex = [self expectationWithDescription:@""];

    [[CALayer layer] promiseAnimation:[CAAnimation new] forKey:@"center"].then(^{
        [ex fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
