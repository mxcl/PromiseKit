@import PromiseKit;
@import XCTest;
#import "Infrastructure.h"

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

- (void)test_36_promise_with_value_nil {
    id ex1 = [self expectationWithDescription:@""];
    
    [AnyPromise promiseWithValue:nil].then(^(id o){
        XCTAssertNil(o);
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
    }).always(^{
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_48_finally_negative {
    id ex1 = [self expectationWithDescription:@""];
    id ex2 = [self expectationWithDescription:@""];

    Injected.errorUnhandler = ^(NSError *err) {
        XCTAssertEqualObjects(err.domain, PMKTestErrorDomain);
        [ex2 fulfill];
    };

    [AnyPromise promiseWithValue:@1].then(^{
        return dummy();
    }).always(^{
        [ex1 fulfill];
    });

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
    }).always(^{
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

- (void)test_52_fulfill_with_rejected_promise {  //NEEDEDanypr
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

- (void)test_58_just_finally {
    id ex1 = [self expectationWithDescription:@""];
    
    AnyPromise *promise = fulfillLater().then(^{
        return nil;
    }).always(^{
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    id ex2 = [self expectationWithDescription:@""];
    
    promise.always(^{
        [ex2 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_properties {
    Injected.errorUnhandler = ^(NSError *err){
        XCTAssertEqualObjects(err.localizedDescription, @"2");
    };

    XCTAssertEqualObjects([AnyPromise promiseWithValue:@1].value, @1);
    XCTAssertEqualObjects([[AnyPromise promiseWithValue:dummyWithCode(2)].value localizedDescription], @"2");
    XCTAssertNil([AnyPromise promiseWithResolverBlock:^(id a){}].value);
    XCTAssertTrue([AnyPromise promiseWithResolverBlock:^(id a){}].pending);
    XCTAssertFalse([AnyPromise promiseWithResolverBlock:^(id a){}].resolved);
    XCTAssertFalse([AnyPromise promiseWithValue:@1].pending);
    XCTAssertTrue([AnyPromise promiseWithValue:@1].resolved);
}

- (void)test_promiseWithValue {
    Injected.errorUnhandler = ^(NSError *err){
        XCTAssertEqualObjects(err.localizedDescription, @"2");
    };

    XCTAssertEqual([AnyPromise promiseWithValue:@1].value, @1);
    XCTAssertEqualObjects([[AnyPromise promiseWithValue:dummyWithCode(2)].value localizedDescription], @"2");
    XCTAssertEqual([AnyPromise promiseWithValue:[AnyPromise promiseWithValue:@1]].value, @1);
}

//- (void)test_nil_block {
//    [AnyPromise promiseWithValue:@1].then(nil);
//    [AnyPromise promiseWithValue:@1].thenOn(nil, nil);
//    [AnyPromise promiseWithValue:@1].catch(nil);
//    [AnyPromise promiseWithValue:@1].always(nil);
//    [AnyPromise promiseWithValue:@1].alwaysOn(nil, nil);
//}

@end
