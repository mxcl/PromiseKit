@import Foundation;
#import <PromiseKit/PromiseKit.h>
@import XCTest;


@interface JoinTestCase_ObjC: XCTestCase @end @implementation JoinTestCase_ObjC

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
              ]).then(^(NSArray *results, NSArray *values, NSArray *errors) {
        NSUInteger cumv = 0;
        NSInteger cume = 0;

        for (id error in errors)
            cume |= [error code];
        for (id value in values)
            cumv |= [value unsignedIntValue];

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
              ]).then(^(NSArray *results, NSArray *values, NSArray *errors) {
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
              ]).then(^(NSArray *results, NSArray *values, NSArray *errors) {
        XCTAssertEqualObjects(values, @[]);
        XCTAssertNotNil(errors);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_76_join_fulfills_if_empty_input {
    XCTestExpectation *ex1 = [self expectationWithDescription:@""];
    PMKJoin(@[]).then(^(id a, id b, id c){
        XCTAssertEqualObjects(@[], a);
        XCTAssertEqualObjects(@[], b);
        XCTAssertNil(c);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
