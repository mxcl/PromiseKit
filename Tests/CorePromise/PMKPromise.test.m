#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@class PMKPromise;

PMKPromise *foo();

#import <PromiseKit/PMKPromise.h>
#import <PromiseKit/Umbrella.h>
@import XCTest;

PMKPromise *foo() {
    return [PMKPromise promiseWithValue:@1];
}

@interface PMKPromiseTests : XCTestCase @end @implementation PMKPromiseTests

- (void)testCanDeclareClassBeforeImport {
    // tests that our compatability layer with PMKPromise is
    // 100% great. Predeclaring @class PMKPromise works and
    // has no linker error either. AnyPromise is the same class.

    id ex1 = [self expectationWithDescription:@""];
    foo().then(^{
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_new_fulfill {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
        fulfill(@1);
    }].then(^(NSNumber *value){
        XCTAssertEqual(value.integerValue, 1);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_new_fulfill_with_error {
    id ex1 = [self expectationWithDescription:@""];
    id err = [NSError errorWithDomain:@"a" code:1 userInfo:nil];

    [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
        fulfill(err);
    }].catch(^(id obj){
        XCTAssertEqualObjects(obj, err);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_new_reject_with_error {
    id ex1 = [self expectationWithDescription:@""];
    id err = [NSError errorWithDomain:@"a" code:1 userInfo:nil];

    [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
        reject(err);
    }].catch(^(id obj){
        XCTAssertEqualObjects(obj, err);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_new_reject_with_string {
    id ex1 = [self expectationWithDescription:@""];
    id sentinel = @"HI";

    [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
        reject(sentinel);
    }].catch(^(NSError *err){
        XCTAssertEqual(PMKInvalidUsageError, err.code);
        XCTAssertEqualObjects(err.domain, PMKErrorDomain);
        XCTAssertEqualObjects(sentinel, err.userInfo[PMKUnderlyingExceptionKey]);
        XCTAssertEqualObjects(sentinel, [err localizedDescription]);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_new_reject_with_number {
    id ex1 = [self expectationWithDescription:@""];
    id sentinel = @1;

    [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
        reject(sentinel);
    }].catch(^(NSError *err){
        XCTAssertEqual(PMKInvalidUsageError, err.code);
        XCTAssertEqualObjects(err.domain, PMKErrorDomain);
        XCTAssertEqualObjects(sentinel, err.userInfo[PMKUnderlyingExceptionKey]);
        XCTAssertEqualObjects([sentinel description], [err localizedDescription]);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_new_reject_with_fulfilled_promise {
    id ex1 = [self expectationWithDescription:@""];
    id sentinel = @"1";

    [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
        reject((id) [AnyPromise promiseWithValue:sentinel]);
    }].catch(^(NSError *err){
        XCTAssertEqual(PMKInvalidUsageError, err.code);
        XCTAssertEqualObjects(err.domain, PMKErrorDomain);
        XCTAssertEqualObjects(sentinel, err.userInfo[PMKUnderlyingExceptionKey]);
        XCTAssertEqualObjects(sentinel, [err localizedDescription]);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_new_reject_with_rejected_promise {
    id ex1 = [self expectationWithDescription:@""];
    id err = [NSError errorWithDomain:@"a" code:1 userInfo:nil];

    [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
        reject((id) [AnyPromise promiseWithValue:err]);
    }].catch(^(id obj){
        XCTAssertEqualObjects(err, obj);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_new_throws_error {
    id ex1 = [self expectationWithDescription:@""];
    id err = [NSError errorWithDomain:@"a" code:1 userInfo:nil];

    [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
        @throw err;
    }].catch(^(id obj){
        XCTAssertEqualObjects(obj, err);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_new_throws_string {
    id ex1 = [self expectationWithDescription:@""];
    id sentinel = @"HI";

    [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
        @throw sentinel;
    }].catch(^(NSError *err){
        XCTAssertEqual(PMKUnexpectedError, err.code);
        XCTAssertEqualObjects(PMKErrorDomain, err.domain);
        XCTAssertEqualObjects([err localizedDescription], sentinel);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_until_fulfills_immediately {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise until:^{
        return [PMKPromise pause:0.01];
    } catch:^(NSError *error){
        XCTFail();
    }].then(^{
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_until_fulfills_eventually {
    id ex1 = [self expectationWithDescription:@""];
    id sentinel = [NSError errorWithDomain:@"a" code:1 userInfo:nil];

    __block int x = 0;

    [PMKPromise until:^{
        return [PMKPromise pause:0.01].then(^{
            if (x++ < 2)
                @throw sentinel;
        });
    } catch:^(NSError *error){
        XCTAssertLessThanOrEqual(x, 2);
        XCTAssertEqualObjects(error.domain, [sentinel domain]);
    }].then(^{
        XCTAssertEqual(x, 3);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_until_rejects_then_fulfills {
    id ex1 = [self expectationWithDescription:@""];

    __block BOOL this_happened_at_least_once = NO;
    __block int x = 0;
    [PMKPromise until:^{
        return [PMKPromise pause:0.01].then(^{
            if (x++ == 0)
                @throw @"1";
        });
    } catch:^(NSError *error){
        return [PMKPromise pause:0.01].then(^{
            this_happened_at_least_once = YES;
        });
    }].then(^{
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];

    XCTAssertTrue(this_happened_at_least_once);
}

- (void)test_until_rejects_then_rejects {
    id ex1 = [self expectationWithDescription:@""];
    NSError *(^sentinel)() = ^{ return [NSError errorWithDomain:@"a" code:1 userInfo:nil]; };

    __block BOOL this_happened = NO;
    __block int x = 0;
    [PMKPromise until:^{
        return [PMKPromise pause:0.01].then(^{
            @throw sentinel();
        });
    } catch:^(NSError *error){
        return [PMKPromise pause:0.01].then(^{
            if (x++ >= 2) {
                this_happened = YES;
                @throw sentinel();
            }
        });
    }].then(^{
        XCTFail();
    }).catch(^{
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:10 handler:nil];

    XCTAssertTrue(this_happened);
}

@end
