#import <PromiseKit/PromiseKit.h>
@import XCTest;

@interface PMKManifoldTests: XCTestCase @end @implementation PMKManifoldTests

- (void)test_62_access_extra_elements {
    id ex1 = [self expectationWithDescription:@""];

    [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        resolve(PMKManifold(@1));
    }].then(^(id o, id m, id n){
        XCTAssertNil(m, @"Accessing extra elements should not crash");
        XCTAssertNil(n, @"Accessing extra elements should not crash");
        XCTAssertEqualObjects(o, @1);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_63_then_manifold {
    id ex1 = [self expectationWithDescription:@""];

    [AnyPromise promiseWithValue:@0].then(^{
        return PMKManifold(@1, @2, @3);
    }).then(^(id o1, id o2, id o3){
        XCTAssertEqualObjects(o1, @1);
        XCTAssertEqualObjects(o2, @2);
        XCTAssertEqualObjects(o3, @3);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_63_then_manifold_with_nil {
    id ex1 = [self expectationWithDescription:@""];

    [AnyPromise promiseWithValue:@0].then(^{
        return PMKManifold(@1, nil, @3);
    }).then(^(id o1, id o2, id o3){
        XCTAssertEqualObjects(o1, @1);
        XCTAssertEqualObjects(o2, nil);
        XCTAssertEqualObjects(o3, @3);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_65_manifold_fulfill_value {
    id ex1 = [self expectationWithDescription:@""];

    AnyPromise *promise = [AnyPromise promiseWithValue:@1].then(^{
        return PMKManifold(@123, @2);
    });

    promise.then(^(id a, id b){
        XCTAssertNotNil(a);
        XCTAssertNotNil(b);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];

    XCTAssertEqualObjects(promise.value, @123);
}

- (void)test_37_PMKMany_2 {
    id ex1 = [self expectationWithDescription:@""];

    PMKAfter(0.02).then(^{
        return PMKManifold(@1, @2);
    }).then(^(id a, id b){
        XCTAssertEqualObjects(a, @1);
        XCTAssertEqualObjects(b, @2);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
