#import "SKRequest+AnyPromise.h"
@import PromiseKit;
@import StoreKit;
@import XCTest;


@implementation PMKSKProductsRequest: SKProductsRequest
- (void)start {
    PMKAfter(0.5).then(^{
        [self.delegate productsRequest:self didReceiveResponse:[SKProductsResponse new]];
    });
}
@end



@implementation Test_SKProductsRequest_ObjC: XCTestCase

- (void)test {
    id ex = [self expectationWithDescription:@""];
    SKProductsRequest *rq = [PMKSKProductsRequest new];
    [rq promise].then(^{
        [ex fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
