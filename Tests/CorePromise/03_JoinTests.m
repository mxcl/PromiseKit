@import Foundation;
@import PromiseKit;
@import XCTest;


@interface JoinTests: XCTestCase @end @implementation JoinTests

- (void)test_73_join {
    XCTestExpectation *ex1 = [self expectationWithDescription:@""];

    __block void (^fulfiller)(id) = nil;
    AnyPromise *promise = [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        fulfiller = resolve;
    }];

    PMKJoin(@[
              [AnyPromise promiseWithValue:[NSError errorWithDomain:@"dom" code:1 userInfo:nil]],
              promise,
              [AnyPromise promiseWithValue:[NSError errorWithDomain:@"dom" code:2 userInfo:nil]]
              ]).then(^{
        XCTFail();
    }).catch(^(NSError *error){
        id promises = error.userInfo[PMKJoinPromisesKey];

        int cume = 0, cumv = 0;

        for (AnyPromise *promise in promises) {
            if ([promise.value isKindOfClass:[NSError class]]) {
                cume |= [promise.value code];
            } else {
                cumv |= [promise.value unsignedIntValue];
            }
        }

        XCTAssertTrue(cumv == 4);
        XCTAssertTrue(cume == 3);

        [ex1 fulfill];
    });
    fulfiller(@4);
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_74_join_no_errors {
    XCTestExpectation *ex1 = [self expectationWithDescription:@""];
    PMKJoin(@[
              [AnyPromise promiseWithValue:@1],
              [AnyPromise promiseWithValue:@2]
              ]).then(^(NSArray *values, id errors) {
        XCTAssertEqualObjects(values, (@[@1, @2]));
        XCTAssertNil(errors);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}


- (void)test_75_join_no_success {
    XCTestExpectation *ex1 = [self expectationWithDescription:@""];
    PMKJoin(@[
              [AnyPromise promiseWithValue:[NSError errorWithDomain:@"dom" code:1 userInfo:nil]],
              [AnyPromise promiseWithValue:[NSError errorWithDomain:@"dom" code:2 userInfo:nil]],
              ]).then(^{
        XCTFail();
    }).catch(^(NSError *error){
        XCTAssertNotNil(error.userInfo[PMKJoinPromisesKey]);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_76_join_fulfills_if_empty_input {
    XCTestExpectation *ex1 = [self expectationWithDescription:@""];
    PMKJoin(@[]).then(^(id a, id b, id c){
        XCTAssertEqualObjects(@[], a);
        XCTAssertNil(b);
        XCTAssertNil(c);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
