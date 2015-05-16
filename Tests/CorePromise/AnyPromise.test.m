#import <PromiseKit/PromiseKit.h>
@import XCTest;

#define PMKTestErrorDomain @"PMKTestErrorDomain"

static inline NSError *dummyWithCode(NSInteger code) {
    return [NSError errorWithDomain:PMKTestErrorDomain code:rand() userInfo:@{NSLocalizedDescriptionKey: @(code).stringValue}];
}

static inline NSError *dummy() {
    return dummyWithCode(rand());
}

static inline AnyPromise *rejectLater() {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                resolve(dummy());
            });
        });
    }];
}

static inline AnyPromise *fulfillLater() {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            resolve(@1);
        });
    }];
}


@interface AnyPromiseTestSuite : XCTestCase @end @implementation AnyPromiseTestSuite

- (void)tearDown {
    PMKSetUnhandledErrorHandler(^(NSError *error) {

    });
}

- (void)test_01_resolve {
    id ex1 = [self expectationWithDescription:@""];
    
    AnyPromise *promise = [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        resolve(@1);
    }];
    promise.then(^(NSNumber *o){
        [ex1 fulfill];
        XCTAssertEqual(o.intValue, 1);
    });
    promise.catch(^{
        XCTFail();
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_02_reject {
    id ex1 = [self expectationWithDescription:@""];
    
    AnyPromise *promise = [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        resolve(dummyWithCode(2));
    }];
    promise.then(^{
        XCTFail();
    });
    promise.catch(^(NSError *error){
        XCTAssertEqualObjects(error.localizedDescription, @"2");
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_03_return_error {
    id ex1 = [self expectationWithDescription:@""];
    
    AnyPromise *promise = [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        resolve(@2);
    }];
    promise.then(^{
        return [NSError errorWithDomain:@"a" code:3 userInfo:nil];
    }).catch(^(NSError *e){
        [ex1 fulfill];
        XCTAssertEqual(3, e.code);
    });
    promise.catch(^{
        XCTFail();
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_04_return_error_doesnt_compromise_result {
    id ex1 = [self expectationWithDescription:@""];
    
    AnyPromise *promise = [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        resolve(@4);
    }].then(^{
        return dummy();
    });
    promise.then(^{
        XCTFail();
    });
    promise.catch(^{
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_05_throw_and_bubble {
    id ex1 = [self expectationWithDescription:@""];
    
    [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        resolve(@5);
    }].then(^(id ii){
        XCTAssertEqual(5, [ii intValue]);
        return [NSError errorWithDomain:@"a" code:[ii intValue] userInfo:nil];
    }).catch(^(NSError *e){
        XCTAssertEqual(e.code, 5);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_05_throw_and_bubble_more {
    id ex1 = [self expectationWithDescription:@""];
    
    [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        resolve(@5);
    }].then(^{
        return dummy();
    }).then(^{
        //NOOP
    }).catch(^(NSError *e){
        [ex1 fulfill];
        XCTAssertEqualObjects(e.domain, PMKTestErrorDomain);
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_06_return_error {
    id ex1 = [self expectationWithDescription:@""];
    
    [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        resolve(@5);
    }].then(^{
        return dummy();
    }).catch(^{
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_07_can_then_resolved {
    id ex1 = [self expectationWithDescription:@""];
    
    [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        resolve(@1);
    }].then(^(id o){
        [ex1 fulfill];
        XCTAssertEqualObjects(@1, o);
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_07a_can_fail_rejected {
    id ex1 = [self expectationWithDescription:@""];
    
    [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        resolve(dummyWithCode(1));
    }].catch(^(NSError *e){
        [ex1 fulfill];
        XCTAssertEqualObjects(@"1", e.localizedDescription);
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_09_async {
    id ex1 = [self expectationWithDescription:@""];
    
    __block int x = 0;
    [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        resolve(@1);
    }].then(^{
        XCTAssertEqual(x, 0);
        x++;
    }).then(^{
        XCTAssertEqual(x, 1);
        x++;
        
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    XCTAssertEqual(x, 2);
}

- (void)test_10_then_returns_resolved_promise {
    id ex1 = [self expectationWithDescription:@""];
    
    [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        resolve(@10);
    }].then(^(id o){
        XCTAssertEqualObjects(@10, o);
        return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
            resolve(@100);
        }];
    }).then(^(id o){
        XCTAssertEqualObjects(@100, o);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_11_then_returns_pending_promise {
    id ex1 = [self expectationWithDescription:@""];
    
    [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        resolve(@1);
    }].then(^{
        return fulfillLater();
    }).then(^(id o){
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_12_then_returns_recursive_promises {
    id ex1 = [self expectationWithDescription:@""];
    id ex2 = [self expectationWithDescription:@""];
    
    __block int x = 0;
    fulfillLater().then(^{
        NSLog(@"1");
        XCTAssertEqual(x++, 0);
        return fulfillLater().then(^{
            NSLog(@"2");
            XCTAssertEqual(x++, 1);
            return fulfillLater().then(^{
                NSLog(@"3");
                XCTAssertEqual(x++, 2);
                return fulfillLater().then(^{
                    NSLog(@"4");
                    XCTAssertEqual(x++, 3);
                    [ex2 fulfill];
                    return @"foo";
                });
            });
        });
    }).then(^(id o){
                NSLog(@"5");
        XCTAssertEqualObjects(@"foo", o);
        XCTAssertEqual(x++, 4);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    XCTAssertEqual(x, 5);
}

 - (void)test_13_then_returns_recursive_promises_that_fails {
     id ex1 = [self expectationWithDescription:@""];
     id ex2 = [self expectationWithDescription:@""];
     
     fulfillLater().then(^{
         return fulfillLater().then(^{
             return fulfillLater().then(^{
                 return fulfillLater().then(^{
                     [ex2 fulfill];
                     return dummy();
                 });
             });
         });
     }).then(^{
         XCTFail();
     }).catch(^(NSError *e){
         XCTAssertEqualObjects(e.domain, PMKTestErrorDomain);
         [ex1 fulfill];
     });

     [self waitForExpectationsWithTimeout:1 handler:nil];
 }

- (void)test_14_fail_returns_value {
    id ex1 = [self expectationWithDescription:@""];
    
    [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        resolve(@1);
    }].then(^{
        return [NSError errorWithDomain:@"a" code:1 userInfo:nil];
    }).catch(^(NSError *e){
        XCTAssertEqual(e.code, 1);
        return @2;
    }).then(^(id o){
        XCTAssertEqualObjects(o, @2);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_15_fail_returns_promise {
    id ex1 = [self expectationWithDescription:@""];
    
    [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        resolve(@1);
    }].then(^{
        return dummy();
    }).catch(^{
        return fulfillLater().then(^{
            return @123;
        });
    }).then(^(id o){
        XCTAssertEqualObjects(o, @123);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_18_when {
    id ex1 = [self expectationWithDescription:@""];
    
    id a = fulfillLater().then(^{ return @345; });
    id b = fulfillLater().then(^{ return @345; });
    PMKWhen(@[a, b]).then(^(NSArray *objs){
        XCTAssertEqual(objs.count, 2ul);
        XCTAssertEqualObjects(objs[0], objs[1]);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_21_recursive_when {
    id ex1 = [self expectationWithDescription:@""];
    id a = fulfillLater().then(^{
        return dummy();
    });
    id b = fulfillLater();
    id c = PMKWhen(@[a, b]);
    PMKWhen(c).then(^{
        XCTFail();
    }).catch(^(NSError *e){
        XCTAssertEqualObjects(e.userInfo[PMKFailingPromiseIndexKey], @0);
        XCTAssertEqualObjects(e.domain, PMKTestErrorDomain);
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
    
    resolve(dummy());
    
    PMKWhen(promise).then(^{
        XCTFail();
    }).catch(^{
        [ex2 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_23_add_another_fail_to_already_rejected {
    id ex1 = [self expectationWithDescription:@""];
    id ex2 = [self expectationWithDescription:@""];
    
    PMKResolver resolve;
    AnyPromise *promise = [[AnyPromise alloc] initWithResolver:&resolve];
    
    promise.then(^{
        XCTFail();
    }).catch(^(NSError *e){
        XCTAssertEqualObjects(e.localizedDescription, @"23");
        [ex1 fulfill];
    });
    
    resolve(dummyWithCode(23));
    
    promise.then(^{
        XCTFail();
    }).catch(^(NSError *e){
        XCTAssertEqualObjects(e.localizedDescription, @"23");
        [ex2 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_24_some_edge_case {
    id ex1 = [self expectationWithDescription:@""];
    id a = fulfillLater().catch(^{});
    id b = fulfillLater();
    PMKWhen(@[a, b]).then(^(NSArray *objs){
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_25_then_plus_deferred_plus_GCD {
    id ex1 = [self expectationWithDescription:@""];
    id ex2 = [self expectationWithDescription:@""];
    id ex3 = [self expectationWithDescription:@""];
    
    fulfillLater().then(^(id o){
        [ex1 fulfill];
        return fulfillLater().then(^{
            return @YES;
        });
    }).then(^(id o){
        XCTAssertEqualObjects(@YES, o);
        [ex2 fulfill];
    }).then(^(id o){
        XCTAssertNil(o);
        [ex3 fulfill];
    }).catch(^{
        XCTFail();
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_26_promise_then_promise_fail_promise_fail {
    id ex1 = [self expectationWithDescription:@""];
    
    fulfillLater().then(^{
        return fulfillLater().then(^{
            return dummy();
        }).catch(^{
            return fulfillLater().then(^{
                return dummy();
            });
        });
    }).then(^{
        XCTFail();
    }).catch(^{
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];}

- (void)test_27_eat_failure {
    id ex1 = [self expectationWithDescription:@""];
    
    fulfillLater().then(^{
        return dummy();
    }).catch(^{
        return @YES;
    }).then(^{
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_28_deferred_rejected_catch_promise {
    id ex1 = [self expectationWithDescription:@""];
    id ex2 = [self expectationWithDescription:@""];

    rejectLater().catch(^{
        [ex1 fulfill];
        return fulfillLater();
    }).then(^(id o){
        [ex2 fulfill];
    }).catch(^{
        XCTFail();
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_29_deferred_rejected_catch_promise {
    id ex1 = [self expectationWithDescription:@""];
    id ex2 = [self expectationWithDescription:@""];
    
    rejectLater().catch(^{
        [ex1 fulfill];
        return fulfillLater().then(^{
            return dummy();
        });
    }).then(^{
        XCTFail(@"1");
    }).catch(^(NSError *error){
        [ex2 fulfill];
    }).catch(^{
        XCTFail(@"2");
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_30_dispatch_returns_pending_promise {
    id ex1 = [self expectationWithDescription:@""];
    dispatch_promise(^{
        return fulfillLater();
    }).then(^{
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_31_dispatch_returns_promise {
    id ex1 = [self expectationWithDescription:@""];
    dispatch_promise(^{
        return [AnyPromise promiseWithValue:@1];
    }).then(^(id o){
        XCTAssertEqualObjects(o, @1);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_32_return_primitive {
    id ex1 = [self expectationWithDescription:@""];
    __block void (^fulfiller)(id) = nil;
    [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        fulfiller = resolve;
    }].then(^(id o){
        XCTAssertEqualObjects(o, @32);
        return 3;
    }).then(^(id o){
        XCTAssertEqualObjects(@3, o);
        [ex1 fulfill];
    });
    fulfiller(@32);
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_33_return_nil {
    id ex1 = [self expectationWithDescription:@""];
    [AnyPromise promiseWithValue:@1].then(^(id o){
        XCTAssertEqualObjects(o, @1);
        return nil;
    }).then(^{
        return nil;
    }).then(^(id o){
        XCTAssertNil(o);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_33a_return_nil {
    id ex1 = [self expectationWithDescription:@""];
    id ex2 = [self expectationWithDescription:@""];
    
    [AnyPromise promiseWithValue:@"HI"].then(^(id o){
        XCTAssertEqualObjects(o, @"HI");
        [ex1 fulfill];
        return nil;
    }).then(^{
        return nil;
    }).then(^{
        [ex2 fulfill];
        return nil;
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_35_when_nil {
    id ex1 = [self expectationWithDescription:@""];
    
    AnyPromise *promise = [AnyPromise promiseWithValue:@"35"].then(^{ return nil; });
    PMKWhen(@[fulfillLater().then(^{ return @1; }), [AnyPromise promiseWithValue:nil], promise]).then(^(NSArray *results){
        XCTAssertEqual(results.count, 3ul);
        XCTAssertEqualObjects(results[1], [NSNull null]);
        [ex1 fulfill];
    }).catch(^(NSError *err){
        abort();
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_36_promise_with_value_nil {
    id ex1 = [self expectationWithDescription:@""];
    
    [AnyPromise promiseWithValue:nil].then(^(id o){
        XCTAssertNil(o);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_37_PMKMany_2 {
    id ex1 = [self expectationWithDescription:@""];
    
    fulfillLater().then(^{
        return PMKManifold(@1, @2);
    }).then(^(id a, id b){
        XCTAssertEqualObjects(a, @1);
        XCTAssertEqualObjects(b, @2);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_39_when_with_some_values {
    id ex1 = [self expectationWithDescription:@""];
    
    id p = fulfillLater();
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
    
    id p = fulfillLater();
    id v = @1;
    PMKWhen(@[p, v, p, v]).then(^(NSArray *aa){
        XCTAssertEqual(aa.count, 4ul);
        XCTAssertEqualObjects(aa[1], @1);
        XCTAssertEqualObjects(aa[3], @1);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_42 {
    id ex1 = [self expectationWithDescription:@""];
    
    [AnyPromise promiseWithValue:@1].then(^{
        return fulfillLater();
    }).then(^{
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_43_return_promise_from_itself {
    id ex1 = [self expectationWithDescription:@""];
    
    AnyPromise *p = fulfillLater().then(^{ return @1; });
    p.then(^{
        return p;
    }).then(^{
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_44_reseal {
    id ex1 = [self expectationWithDescription:@""];
    
    [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        resolve(@123);
        resolve(@234);
    }].then(^(id o){
        XCTAssertEqualObjects(o, @123);
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


- (void)test_46_test_then_on {
    id ex1 = [self expectationWithDescription:@""];
    
    dispatch_queue_t q1 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    dispatch_queue_t q2 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [AnyPromise promiseWithValue:@1].thenOn(q1, ^{
        XCTAssertFalse([NSThread isMainThread]);
        return dispatch_get_current_queue();
    }).thenOn(q2, ^(id q){
        XCTAssertFalse([NSThread isMainThread]);
        XCTAssertNotEqualObjects(q, dispatch_get_current_queue());
        [ex1 fulfill];
    });
#pragma clang diagnostic pop
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_47_finally_plus {
    id ex1 = [self expectationWithDescription:@""];
    
    [AnyPromise promiseWithValue:@1].then(^{
        return @1;
    }).finally(^{
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_48_finally_negative {
    @autoreleasepool {
        id ex1 = [self expectationWithDescription:@""];
        id ex2 = [self expectationWithDescription:@""];
        
        PMKSetUnhandledErrorHandler(^(NSError *error){
            [ex2 fulfill];
        });
        
        [AnyPromise promiseWithValue:@1].then(^{
            return dummy();
        }).finally(^{
            [ex1 fulfill];
        });
    }
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_49_finally_negative_later {
    id ex1 = [self expectationWithDescription:@""];
    __block int x = 0;
    
    [AnyPromise promiseWithValue:@1].then(^{
        XCTAssertEqual(++x, 1);
        return dummy();
    }).catch(^{
        XCTAssertEqual(++x, 2);
    }).then(^{
        XCTAssertEqual(++x, 3);
    }).finally(^{
        XCTAssertEqual(++x, 4);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_50_fulfill_with_pending_promise {
    id ex1 = [self expectationWithDescription:@""];
    
    [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        resolve(fulfillLater().then(^{ return @"HI"; }));
    }].then(^(id hi){
        XCTAssertEqualObjects(hi, @"HI");
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_51_fulfill_with_fulfilled_promise {
    id ex1 = [self expectationWithDescription:@""];
    
    [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        resolve([AnyPromise promiseWithValue:@1]);
    }].then(^(id o){
        XCTAssertEqualObjects(o, @1);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_52_fulfill_with_rejected_promise {
    id ex1 = [self expectationWithDescription:@""];
    fulfillLater().then(^{
        return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
            resolve([AnyPromise promiseWithValue:dummy()]);
        }];
    }).catch(^(NSError *err){
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_53_return_rejected_promise {
    id ex1 = [self expectationWithDescription:@""];
    fulfillLater().then(^{
        return @1;
    }).then(^{
        return [AnyPromise promiseWithValue:dummy()];
    }).catch(^{
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_54_reject_with_rejected_promise {
    id ex1 = [self expectationWithDescription:@""];
    
    [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        id err = [NSError errorWithDomain:@"a" code:123 userInfo:nil];
        resolve([AnyPromise promiseWithValue:err]);
    }].catch(^(NSError *err){
        XCTAssertEqual(err.code, 123);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_55_all_dictionary {
    id ex1 = [self expectationWithDescription:@""];
    
    id promises = @{
        @1: @2,
        @2: @"abc",
        @"a": fulfillLater().then(^{ return @"HI"; })
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

- (void)test_58_just_finally {
    id ex1 = [self expectationWithDescription:@""];
    
    AnyPromise *promise = fulfillLater().then(^{
        return nil;
    }).finally(^{
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    id ex2 = [self expectationWithDescription:@""];
    
    promise.finally(^{
        [ex2 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_59_typedef {
    id ex1 = [self expectationWithDescription:@""];
    
    AnyPromise *p1 = [AnyPromise promiseWithValue:@1];
    XCTAssertEqualObjects(p1.value, @1);
    
    p1.then(^(id o){
        XCTAssertEqualObjects(o, @1);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

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

//- (void)test_66_until {
//    id ex1 = [self expectationWithDescription:@""];
//    
//    __block BOOL this_happened = NO;
//    __block int x = 0;
//    [AnyPromise until:^{
//        return dispatch_promise(^{
//            if (x++ < 2)
//                @throw @"no";
//        });
//    } catch:^(NSError *error){
//        return dispatch_promise(^{
//            this_happened = YES;
//        });
//    }].then(^{
//        [ex1 fulfill];
//    });
//    
//    [self waitForExpectationsWithTimeout:1 handler:nil];
//    
//    XCTAssertTrue(this_happened);
//}

//- (void)test_67_until_failure {
//    id ex1 = [self expectationWithDescription:@""];
//    
//    __block BOOL this_happened = NO;
//    __block int x = 0;
//    [AnyPromise until:^{
//        return dispatch_promise(^{
//            @throw @"no";
//        });
//    } catch:^(NSError *error){
//        return dispatch_promise(^{
//            this_happened = YES;
//            if (x++ >= 2)
//                @throw @"no";
//        });
//    }].then(^{
//        XCTFail();
//    }).catch(^{
//        [ex1 fulfill];
//    });
//    
//    [self waitForExpectationsWithTimeout:1 handler:nil];
//    
//    XCTAssertTrue(this_happened);
//}

- (void)test_68_unhandled_error_handler {
    @autoreleasepool {
        XCTestExpectation *ex = [self expectationWithDescription:@""];
        
        PMKSetUnhandledErrorHandler(^(NSError *error){
            XCTAssertEqualObjects(@"5", error.localizedDescription);
            [ex fulfill];
        });
        
        [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
            resolve(dummyWithCode(5));
        }];
    }
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_69_unhandled_handled_returned {
    @autoreleasepool {
        XCTestExpectation *ex1 = [self expectationWithDescription:@"unhandler"];
        XCTestExpectation *ex2 = [self expectationWithDescription:@"initial catch"];

        PMKSetUnhandledErrorHandler(^(NSError *error){
            XCTAssertEqualObjects(@"5", error.localizedDescription);
            [ex1 fulfill];
        });

        [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
            resolve(dummyWithCode(5));
        }].catch(^(id e){
            [ex2 fulfill];
            return e;
        }).then(^{
            XCTFail();
        });
    }
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_70_unhandled_error_handler_not_called {
    @autoreleasepool {
        XCTestExpectation *ex1 = [self expectationWithDescription:@""];
        
        PMKSetUnhandledErrorHandler(^(NSError *error){
            XCTFail();
        });
        
        [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
            resolve(dummyWithCode(5));
        }].catch(^{
            return dispatch_promise(^{
                return dispatch_promise(^{
                    return dummyWithCode(5);
                });
            });
        }).catch(^{
            [ex1 fulfill];
        });
    }
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

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

- (void)test_77_hang {
    __block int x = 0;
    id value = PMKHang(fulfillLater().then(^{ x++; return 1; }));
    XCTAssertEqual(x, 1);
    XCTAssertEqualObjects(value, @1);
}

//- (void)test_78_zalgo {
//    __block int x = 0;
//    
//    id ex = [self expectationWithDescription:@""];
//    dispatch_promise(^{
//        XCTAssertEqual(x, 0);
//        dispatch_zalgo(^{
//            XCTAssertEqual(x, 0);
//            x++;
//        });
//        XCTAssertEqual(x, 1);
//        [ex fulfill];
//    });
//    [self waitForExpectationsWithTimeout:1 handler:nil];
//    XCTAssertEqual(x, 1);
//    
//    [AnyPromise promiseWithValue:@1].thenUnleashZalgo(^{
//        x++;
//    });
//    XCTAssertEqual(x, 2);
//}

- (void)test_79_unhandled_error_handler_not_called_reject_passed_through {
    @autoreleasepool {
        XCTestExpectation *ex1 = [self expectationWithDescription:@""];
        
        PMKSetUnhandledErrorHandler(^(NSError *error) {
            XCTFail();
        });
        
        [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
            dispatch_promise(^{
                return dummy();
            }).catch(resolve);
        }].catch(^{
            [ex1 fulfill];
        });
    }
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_80_unhandled_error_handler_called_if_reject_passed_through {
    @autoreleasepool {
        XCTestExpectation *ex1 = [self expectationWithDescription:@""];
        XCTestExpectation *ex2 = [self expectationWithDescription:@""];
        
        __block BOOL ex1Fulfilled = NO;

        PMKSetUnhandledErrorHandler(^(NSError *error) {
            XCTAssert(ex1Fulfilled);
            [ex2 fulfill];
        });
        
        [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
            dispatch_promise(^{
                return dummy();
            }).catch(resolve);
        }].finally(^{
            [ex1 fulfill];
            ex1Fulfilled = YES;
        });
    }
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end


@interface WTFError : NSError @end
@implementation WTFError @end


@implementation AnyPromiseTestSuite (More)

- (void)test_999_allow_error_subclasses {
    XCTestExpectation *ex1 = [self expectationWithDescription:@""];
    
    fulfillLater().then(^{
        return [WTFError errorWithDomain:@"WTF" code:0 userInfo:nil];
    }).catch(^(NSError *e){
        XCTAssertEqualObjects(e.class, WTFError.class);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end



__attribute__((objc_runtime_name("PMKPromiseBridgeHelper")))
__attribute__((objc_subclassing_restricted))
@interface PromiseBridgeHelper: NSObject
- (AnyPromise *)bridge1;
@end

@interface TestPromiseBridge: XCTestCase
@end

@implementation TestPromiseBridge

- (void)test1 {
    XCTestExpectation *ex = [self expectationWithDescription:@""];
    AnyPromise *promise = fulfillLater();
    for (int x = 0; x < 100; ++x) {
        promise = promise.then(^{
            return [[[PromiseBridgeHelper alloc] init] bridge1];
        });
    }
    promise.then(^{
        [ex fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

@end
