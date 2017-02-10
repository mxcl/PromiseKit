// Most of the machinery of `Promise` is tested elsewhere since it is
// internally a Swift mixin. This file tests the unique (ObjC) portions.

@import PromiseKit;
@import XCTest;

#define PMKTestError [NSError errorWithDomain:@"a" code:1 userInfo:nil]


@interface Fundamentals : XCTestCase @end @implementation Fundamentals

- (void)test1a {
    id ex = [self expectationWithDescription:@""];

    [AnyPromise promiseWithValue:@1].then(^{
        [ex fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test1b {
    id ex = [self expectationWithDescription:@""];

    [AnyPromise promiseWithValue:@1].then(^(id obj){
        XCTAssertEqual(obj, @1);
        [ex fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test2a {
    id ex = [self expectationWithDescription:@""];

    [AnyPromise promiseWithValue:PMKTestError].catch(^{
        [ex fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test2b {
    id ex = [self expectationWithDescription:@""];

    [AnyPromise promiseWithValue:PMKTestError].catch(^(NSError *err){
        XCTAssertEqual(err.domain, PMKTestError.domain);
        XCTAssertEqual(err.code, PMKTestError.code);
        [ex fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test3 {
    id ex = [self expectationWithDescription:@""];

    [AnyPromise promiseWithValue:@3].ensure(^{
        [ex fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test4 {
    id ex = [self expectationWithDescription:@""];

    [AnyPromise promiseWithValue:PMKTestError].ensure(^{
        [ex fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test5a {
    id ex = [self expectationWithDescription:@""];

    [AnyPromise promiseWithValue:@"a"].then(^{
        return @5;
    }).then(^(id obj){
        XCTAssertEqual(obj, @5);
        [ex fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test5b {
    id ex = [self expectationWithDescription:@""];

    [AnyPromise promiseWithValue:@"a"].then(^{
        return @"5b";
    }).catch(^{
        XCTFail();
    }).then(^(id obj){
        XCTAssertEqual(obj, @"5b");
        [ex fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test5c {
    id ex1 = [self expectationWithDescription:@""];
    id ex2 = [self expectationWithDescription:@""];

    [AnyPromise promiseWithValue:@"a"].then(^{
        return @"5c";
    }).ensure(^{
        [ex1 fulfill];
    }).then(^(id obj){
        XCTAssertEqual(obj, @"5c");
        [ex2 fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test6 {
    id ex1 = [self expectationWithDescription:@""];
    id ex2 = [self expectationWithDescription:@""];
    id ex3 = [self expectationWithDescription:@""];

    [AnyPromise promiseWithValue:@"a"].then(^{
        @throw @"e6";
    }).ensure(^{
        [ex1 fulfill];
    }).catch(^(NSError *err){
        XCTAssertEqual(err.code, PMKUnexpectedError);
        XCTAssertEqual(err.domain, PMKErrorDomain);
        XCTAssertEqual(err.userInfo[NSLocalizedDescriptionKey], @"e6");
        [ex2 fulfill];
    }).then(^{
        [ex3 fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test100a {
    XCTAssertEqual([AnyPromise promiseWithValue:@1].value, @1);
    XCTAssertTrue([AnyPromise promiseWithValue:@1].resolved);
    XCTAssertTrue([AnyPromise promiseWithValue:@1].fulfilled);
    XCTAssertFalse([AnyPromise promiseWithValue:@1].rejected);
    XCTAssertFalse([AnyPromise promiseWithValue:@1].pending);
}

- (void)test100b {
    XCTAssertEqual([[AnyPromise promiseWithValue:PMKTestError].value code], 1);
    XCTAssertTrue([AnyPromise promiseWithValue:PMKTestError].resolved);
    XCTAssertFalse([AnyPromise promiseWithValue:PMKTestError].fulfilled);
    XCTAssertTrue([AnyPromise promiseWithValue:PMKTestError].rejected);
    XCTAssertFalse([AnyPromise promiseWithValue:PMKTestError].pending);
}

- (void)test100c {
    XCTAssertNil([AnyPromise new].value);
    XCTAssertTrue([AnyPromise new].resolved);
    XCTAssertTrue([AnyPromise new].fulfilled);
    XCTAssertFalse([AnyPromise new].rejected);
    XCTAssertFalse([AnyPromise new].pending);
}

- (void)test100d {
    XCTAssertNil([AnyPromise promiseWithResolverBlock:^(id __unused obj){}].value);
    XCTAssertFalse([AnyPromise promiseWithResolverBlock:^(id __unused obj){}].resolved);
    XCTAssertFalse([AnyPromise promiseWithResolverBlock:^(id __unused obj){}].fulfilled);
    XCTAssertFalse([AnyPromise promiseWithResolverBlock:^(id __unused obj){}].rejected);
    XCTAssertTrue([AnyPromise promiseWithResolverBlock:^(id __unused obj){}].pending);
}

@end
