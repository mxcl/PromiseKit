#import "SKRequest+AnyPromise.h"
#import <PromiseKit/PromiseKit.h>
@import StoreKit;
@import Stubbilino;
@import XCTest;

@implementation Test_SKProductsRequest_ObjC: XCTestCase

- (void)test {
    id ex = [self expectationWithDescription:@""];
    SKProductsRequest *rq = [SKProductsRequest new];

    id stub = [Stubbilino stubObject:rq];
    [stub stubMethod:@selector(start) withBlock:^{
        PMKAfter(0.5).then(^{
            [rq.delegate productsRequest:rq didReceiveResponse:[SKProductsResponse new]];
        });
    }];

    [rq promise].then(^{
        [ex fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
