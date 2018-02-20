@import Foundation;
@import PromiseKit;
@import XCTest;


@interface WhenTests: XCTestCase @end @implementation WhenTests

- (void)testProgress {

    id ex = [self expectationWithDescription:@""];

    XCTAssertNil([NSProgress currentProgress]);

    id p1 = PMKAfter(0.01);
    id p2 = PMKAfter(0.02);
    id p3 = PMKAfter(0.03);
    id p4 = PMKAfter(0.04);

    NSProgress *progress = [NSProgress progressWithTotalUnitCount:1];
    [progress becomeCurrentWithPendingUnitCount:1];

    PMKWhen(@[p1, p2, p3, p4]).then(^{
        XCTAssertEqual(progress.completedUnitCount, 1);
        [ex fulfill];
    });

    [progress resignCurrent];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testProgressDoesNotExceed100Percent {

    id ex1 = [self expectationWithDescription:@""];
    id ex2 = [self expectationWithDescription:@""];

    XCTAssertNil([NSProgress currentProgress]);

    id p1 = PMKAfter(0.01);
    id p2 = PMKAfter(0.02).then(^{ return [NSError errorWithDomain:@"a" code:1 userInfo:nil]; });
    id p3 = PMKAfter(0.03);
    id p4 = PMKAfter(0.04);

    id promises = @[p1, p2, p3, p4];

    NSProgress *progress = [NSProgress progressWithTotalUnitCount:1];
    [progress becomeCurrentWithPendingUnitCount:1];

    PMKWhen(promises).catch(^{
        [ex2 fulfill];
    });

    [progress resignCurrent];

    PMKJoin(promises).catch(^{
        XCTAssertLessThanOrEqual(1, progress.fractionCompleted);
        XCTAssertEqual(progress.completedUnitCount, 1);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testWhenManifolds {
    id ex = [self expectationWithDescription:@""];
    id p1 = dispatch_promise(^{ return PMKManifold(@1, @2); });
    id p2 = dispatch_promise(^{});
    PMKWhen(@[p1, p2]).then(^(NSArray *results){
        XCTAssertEqualObjects(results[0], @1);
        XCTAssertEqualObjects(results[1], [NSNull null]);
        [ex fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_55_all_dictionary {
    id ex1 = [self expectationWithDescription:@""];

    id promises = @{
          @1: @2,
          @2: @"abc",
        @"a": PMKAfter(0.1).then(^{ return @"HI"; })
    };
    PMKWhen(promises).then(^(NSDictionary *dict){
        XCTAssertEqual(dict.count, 3ul);
        XCTAssertEqualObjects(dict[@1], @2);
        XCTAssertEqualObjects(dict[@2], @"abc");
        XCTAssertEqualObjects(dict[@"a"], @"HI");
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_56_empty_array_when {
    id ex1 = [self expectationWithDescription:@""];

    PMKWhen(@[]).then(^(NSArray *array){
        XCTAssertEqual(array.count, 0ul);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_57_empty_array_all {
    id ex1 = [self expectationWithDescription:@""];

    PMKWhen(@[]).then(^(NSArray *array){
        XCTAssertEqual(array.count, 0ul);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_18_when {
    id ex1 = [self expectationWithDescription:@""];

    id a = PMKAfter(0.02).then(^{ return @345; });
    id b = PMKAfter(0.03).then(^{ return @345; });
    PMKWhen(@[a, b]).then(^(NSArray *objs){
        XCTAssertEqual(objs.count, 2ul);
        XCTAssertEqualObjects(objs[0], objs[1]);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_21_recursive_when {
    id domain = @"sdjhfg";

    id ex1 = [self expectationWithDescription:@""];
    id a = PMKAfter(0.03).then(^{
        return [NSError errorWithDomain:domain code:123 userInfo:nil];
    });
    id b = PMKAfter(0.02);
    id c = PMKWhen(@[a, b]);
    PMKWhen(c).then(^{
        XCTFail();
    }).catch(^(NSError *e){
        XCTAssertEqualObjects(e.userInfo[PMKFailingPromiseIndexKey], @0);
        XCTAssertEqualObjects(e.domain, domain);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_22_already_resolved_and_bubble {
    id ex1 = [self expectationWithDescription:@""];
    id ex2 = [self expectationWithDescription:@""];

    PMKResolver resolve;
    AnyPromise *promise = [[AnyPromise alloc] initWithResolver:&resolve];

    promise.then(^{
        XCTFail();
    }).catch(^(NSError *e){
        [ex1 fulfill];
    });

    resolve([NSError errorWithDomain:@"a" code:1 userInfo:nil]);

    PMKWhen(promise).then(^{
        XCTFail();
    }).catch(^{
        [ex2 fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_24_some_edge_case {
    id ex1 = [self expectationWithDescription:@""];
    id a = PMKAfter(0.02).catch(^{});
    id b = PMKAfter(0.03);
    PMKWhen(@[a, b]).then(^(NSArray *objs){
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_35_when_nil {
    id ex1 = [self expectationWithDescription:@""];

    AnyPromise *promise = [AnyPromise promiseWithValue:@"35"].then(^{ return nil; });
    PMKWhen(@[PMKAfter(0.02).then(^{ return @1; }), [AnyPromise promiseWithValue:nil], promise]).then(^(NSArray *results){
        XCTAssertEqual(results.count, 3ul);
        XCTAssertEqualObjects(results[1], [NSNull null]);
        [ex1 fulfill];
    }).catch(^(NSError *err){
        abort();
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}


- (void)test_39_when_with_some_values {
    id ex1 = [self expectationWithDescription:@""];

    id p = PMKAfter(0.02);
    id v = @1;
    PMKWhen(@[p, v]).then(^(NSArray *aa){
        XCTAssertEqual(aa.count, 2ul);
        XCTAssertEqualObjects(aa[1], @1);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_40_when_with_all_values {
    id ex1 = [self expectationWithDescription:@""];

    PMKWhen(@[@1, @2]).then(^(NSArray *aa){
        XCTAssertEqualObjects(aa[0], @1);
        XCTAssertEqualObjects(aa[1], @2);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_41_when_with_repeated_promises {
    id ex1 = [self expectationWithDescription:@""];

    id p = PMKAfter(0.02);
    id v = @1;
    PMKWhen(@[p, v, p, v]).then(^(NSArray *aa){
        XCTAssertEqual(aa.count, 4ul);
        XCTAssertEqualObjects(aa[1], @1);
        XCTAssertEqualObjects(aa[3], @1);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_45_when_which_returns_void {
    id ex1 = [self expectationWithDescription:@""];

    AnyPromise *promise = [AnyPromise promiseWithValue:@1].then(^{});
    PMKWhen(@[promise, [AnyPromise promiseWithValue:@1]]).then(^(NSArray *stuff){
        XCTAssertEqual(stuff.count, 2ul);
        XCTAssertEqualObjects(stuff[0], [NSNull null]);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_when_nil {
    NSArray *foo = nil;
    NSError *err = PMKWhen(foo).value;
    XCTAssertEqual(err.domain, PMKErrorDomain);
    XCTAssertEqual(err.code, PMKInvalidUsageError);
}


- (void)test_when_bad_input {
    id foo = @"a";
    XCTAssertEqual(PMKWhen(foo).value, foo);
}

@end
