#import <PromiseKit/PromiseKit.h>
#import "UIViewController+AnyPromise.h"
@import Stubbilino;
@import Social;
@import UIKit;
@import XCTest;

@interface TestPromiseSLComposeViewController: XCTestCase
@end

@implementation TestPromiseSLComposeViewController

- (void)__test:(SLComposeViewControllerResult)dummy :(void (^)(AnyPromise *, id expectation))block {
    id rootvc = [UIViewController new];
    id ex = [self expectationWithDescription:@""];

    SLComposeViewController *composevc = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];

    id stub = [Stubbilino stubObject:rootvc];
    [stub stubMethod:@selector(presentViewController:animated:completion:) withBlock:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            composevc.completionHandler(dummy);
        });
    }];

    block([rootvc promiseViewController:composevc animated:NO completion:nil], ex);

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test1 {
    NSInteger dummy = SLComposeViewControllerResultDone;

    [self __test:dummy :^(AnyPromise *promise, id expectation) {
        promise.then(^(id result){
            XCTAssertEqual([result integerValue], dummy);
            [expectation fulfill];
        });
    }];
}

- (void)test2 {
    [self __test:SLComposeViewControllerResultCancelled :^(AnyPromise *promise, id expectation) {
        promise.catchWithPolicy(PMKCatchPolicyAllErrors, ^(NSError *error){
            XCTAssertTrue(error.cancelled);
            [expectation fulfill];
        });
    }];
}

@end
