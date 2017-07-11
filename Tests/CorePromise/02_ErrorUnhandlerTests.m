@import PromiseKit;
@import XCTest;
#import "Infrastructure.h"

@interface WTFError : NSError @end @implementation WTFError
@end


@interface ErrorUnhandlerTests: XCTestCase @end @implementation ErrorUnhandlerTests

- (void)test_68_unhandled_error_handler {
    @autoreleasepool {
        XCTestExpectation *ex = [self expectationWithDescription:@""];

        Injected.errorUnhandler = ^(NSError *error){
            XCTAssertEqual(error.code, 5);
            XCTAssertEqualObjects(@"a", error.domain);
            [ex fulfill];
        };

        (void) [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
            resolve([NSError errorWithDomain:@"a" code:5 userInfo:@{@"1": @2}]);
        }];
    }
    [self waitForExpectationsWithTimeout:2 handler:nil];
}


- (void)test_69_unhandled_handled_returned {
    @autoreleasepool {
        XCTestExpectation *ex1 = [self expectationWithDescription:@"unhandler"];
        XCTestExpectation *ex2 = [self expectationWithDescription:@"initial catch"];

        Injected.errorUnhandler = ^(NSError *error){
            XCTAssertEqual(5, error.code);
            [ex1 fulfill];
        };

        [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
            resolve([NSError errorWithDomain:@"a" code:5 userInfo:nil]);
        }].catch(^(id e){
            [ex2 fulfill];
            return e;
        }).then(^{
            XCTFail();
        });
    }
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_70_unhandled_error_handler_not_called {
    Injected.errorUnhandler = ^(id err){
        XCTFail();
    };

    @autoreleasepool {
        XCTestExpectation *ex1 = [self expectationWithDescription:@""];

        [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
            resolve([NSError errorWithDomain:@"a" code:5 userInfo:nil]);
        }].catch(^{
            return dispatch_promise(^{
                return dispatch_promise(^{
                    @throw @"5";
                });
            });
        }).catch(^{
            [ex1 fulfill];
        });
    }

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_79_unhandled_error_handler_not_called_reject_passed_through {
    @autoreleasepool {
        XCTestExpectation *ex1 = [self expectationWithDescription:@""];

        Injected.errorUnhandler = ^(id e){
            XCTFail();
        };

        [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
            dispatch_promise(^{
                @throw @"1";
            }).catch(resolve);
        }].catch(^{
            [ex1 fulfill];
        });
    }

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_80_unhandled_error_handler_called_if_reject_passed_through {
    @autoreleasepool {
        XCTestExpectation *ex1 = [self expectationWithDescription:@""];
        XCTestExpectation *ex2 = [self expectationWithDescription:@""];

        __block BOOL ex1Fulfilled = NO;

        Injected.errorUnhandler = ^(id e){
            XCTAssert(ex1Fulfilled);
            [ex2 fulfill];
        };

        [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
            dispatch_promise(^{
                @throw @"1";
            }).catch(resolve);
        }].always(^{
            [ex1 fulfill];
            ex1Fulfilled = YES;
        });
    }
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_999_allow_error_subclasses {
    XCTestExpectation *ex1 = [self expectationWithDescription:@""];

    PMKAfter(0.02).then(^{
        return [WTFError errorWithDomain:@"WTF" code:0 userInfo:nil];
    }).catch(^(NSError *e){
        XCTAssertEqualObjects(e.class, WTFError.class);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
