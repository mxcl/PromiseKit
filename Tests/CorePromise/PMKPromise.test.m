@class PMKPromise;

PMKPromise *foo();

#import <PromiseKit/PromiseKit.h>
#import <CommonCrypto/CommonCrypto.h>

@import XCTest;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wimplicit-retain-self"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"


static inline NSError *dummyWithCode(NSInteger code) {
    return [NSError errorWithDomain:@"PMKTestErrorDomain" code:code userInfo:nil];
}

static inline NSError *dummyError() {
    return dummyWithCode(arc4random());
}

@interface PMKPromise (BackCompat2)
+ (PMKPromise *)hang:(id)input;
@end

@implementation PMKPromise (BackCompat2)
+ (PMKPromise *)hang:(id)input {
    return PMKHang(input);
}
@end

PMKPromise *foo() {
    return [PMKPromise promiseWithValue:@1];
}



@interface PMKPromiseTestSuite : XCTestCase
@end


@implementation PMKPromiseTestSuite

- (void)tearDown {
    PMKSetUnhandledErrorHandler(^(id err){});
}

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

- (void)test_01_resolve {
    id ex1 = [self expectationWithDescription:@""];

    PMKPromise *promise = [PMKPromise new:^(void (^f)(id), id r){
        f(@1);
    }];
    promise.then(^(NSNumber *o){
        [ex1 fulfill];
        XCTAssertEqual(o.intValue, 1);
    });
    promise.catch(^{
        XCTFail();
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_02_reject {
    id ex1 = [self expectationWithDescription:@""];

    PMKPromise *promise = [PMKPromise new:^(id f, void (^r)(id)){
        r(@2);
    }];
    promise.then(^{
        XCTFail();
    });
    promise.catch(^(NSError *error){
        XCTAssertEqualObjects(error.localizedDescription, @"2");
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_03_throw {
    id ex1 = [self expectationWithDescription:@""];

    PMKPromise *promise = [PMKPromise new:^(void (^f)(id), id r){
        f(@2);
    }];
    promise.then(^{
        @throw @"3";
    }).catch(^(NSError *e){
        [ex1 fulfill];
        XCTAssertEqualObjects(@"3", e.localizedDescription);
    });
    promise.catch(^{
        XCTFail();
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_04_throw_doesnt_compromise_result {
    id ex1 = [self expectationWithDescription:@""];

    AnyPromise *promise = [PMKPromise new:^(void (^f)(id), id r){
        f(@4);
    }].then(^{
        @throw @"4";
    });
    promise.then(^{
        XCTFail();
    });
    promise.catch(^{
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_05_throw_and_bubble {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise new:^(void (^f)(id), id r){
        f(@5);
    }].then(^(id ii){
        XCTAssertEqual(5, [ii intValue]);
        @throw [ii description];
    }).catch(^(NSError *e){
        XCTAssertEqualObjects(e.localizedDescription, @"5");
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_05_throw_and_bubble_more {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise new:^(void (^f)(id), id r){
        f(@5);
    }].then(^{
        @throw @"5";
    }).then(^{
        //NOOP
    }).catch(^(NSError *e){
        [ex1 fulfill];
        XCTAssertEqualObjects(e.localizedDescription, @"5");
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_06_return_error {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise new:^(void (^f)(id), id r){
        f(@5);
    }].then(^{
        return dummyError();
    }).catch(^{
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_07_can_then_resolved {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise new:^(void (^f)(id), id r){
        f(@1);
    }].then(^(id o){
        [ex1 fulfill];
        XCTAssertEqualObjects(@1, o);
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_07a_can_fail_rejected {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise new:^(id f, void (^r)(id)){
        r(@1);
    }].catch(^(NSError *e){
        [ex1 fulfill];
        XCTAssertEqualObjects(@"1", e.localizedDescription);
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

// - (void)test_08_url_connection {
//     id ex1 = [self expectationWithDescription:@""];
//
//     [NSURLConnection GET:URL].then(^{
//         [ex1 fulfill];
//     });
//
//     [self waitForExpectationsWithTimeout:20 handler:nil];
// }

- (void)test_09_async {
    id ex1 = [self expectationWithDescription:@""];

    __block int x = 0;
    [PMKPromise new:^(void (^f)(id), id r){
        f(@1);
    }].then(^{
        XCTAssertEqual(x, 0);
        x++;
    }).then(^{
        XCTAssertEqual(x, 1);
        x++;

        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:20 handler:nil];

    XCTAssertEqual(x, 2);
}

- (void)test_10_then_returns_resolved_promise {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise new:^(void (^f)(id), id r){
        f(@10);
    }].then(^(id o){
        XCTAssertEqualObjects(@10, o);
        return [PMKPromise new:^(PMKFulfiller _fulfiller, id r){
            _fulfiller(@100);
        }];
    }).then(^(id o){
        XCTAssertEqualObjects(@100, o);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:20 handler:nil];
}

- (void)test_11_then_returns_pending_promise {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise new:^(void (^f)(id), id r){
        f(@1);
    }].then(^{
        return [PMKPromise pause:0.01];
    }).then(^(id o){
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:20 handler:nil];
}

- (void)test_12_then_returns_recursive_promises {
    id ex1 = [self expectationWithDescription:@""];

    __block int x = 0;
    [PMKPromise pause:0.01].then(^{
        XCTAssertEqual(x++, 0);
        return [PMKPromise pause:0.01].then(^{
            XCTAssertEqual(x++, 1);
            return [PMKPromise pause:0.01].then(^{
                XCTAssertEqual(x++, 2);
                return [PMKPromise pause:0.01].then(^{
                    XCTAssertEqual(x++, 3);
                    return @"foo";
                });
            });
        });
    }).then(^(id o){
        XCTAssertEqualObjects(@"foo", o);
        XCTAssertEqual(x++, 4);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:20 handler:nil];

    XCTAssertEqual(x, 5);
}

- (void)test_13_then_returns_recursive_promises_that_fails {
    id ex = [self expectationWithDescription:@""];

    PMKAfter(0.01).then(^{
        return PMKAfter(0.01).then(^{
            return PMKAfter(0.01).then(^{
                return PMKAfter(0.01).then(^{
                    @throw @"1";
                });
            });
        });
    }).then(^{
        XCTFail();
    }).catch(^(NSError *e){
        XCTAssertEqualObjects(e.localizedDescription, @"1");
        [ex fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_14_fail_returns_value {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise new:^(void (^f)(id), id r){
        f(@1);
    }].then(^{
        @throw @"1";
    }).catch(^(NSError *e){
        XCTAssertEqualObjects(e.localizedDescription, @"1");
        return @2;
    }).then(^(id o){
        XCTAssertEqualObjects(o, @2);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_15_fail_returns_promise {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise new:^(void (^f)(id), id r){
        f(@1);
    }].then(^{
        @throw @"1";
    }).catch(^{
        return [PMKPromise pause:0.01].then(^{
            return @123;
        });
    }).then(^(id o){
        XCTAssertEqualObjects(o, @123);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_18_when {
    id ex1 = [self expectationWithDescription:@""];

    id a = [PMKPromise pause:0.01].then(^{ return @345; });
    id b = [PMKPromise pause:0.01].then(^{ return @345; });
    [PMKPromise when:@[a, b]].then(^(NSArray *objs){
        XCTAssertEqual(objs.count, 2ul);
        XCTAssertEqualObjects(objs[0], objs[1]);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_20_md5 {
    id ex1 = [self expectationWithDescription:@""];
    id input = @"hi";

    dispatch_promise(^{
        XCTAssertFalse([NSThread isMainThread]);

        const char *cstr = [input UTF8String];
        NSUInteger const clen = [input lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        unsigned char result[16];
        CC_MD5(cstr, (CC_LONG)clen, result);
        return [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                result[0],  result[1],  result[2],  result[3],
                result[4],  result[5],  result[6],  result[7],
                result[8],  result[9], result[10], result[11],
                result[12], result[13], result[14], result[15]];

    }).then(^(id md5){
        XCTAssertEqualObjects(md5, @"49F68A5C8493EC2C0BF489821C21FC3B");
        return dispatch_promise(^{
            return nil;
        });
    }).then(^{
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_21_recursive_when {
    id ex1 = [self expectationWithDescription:@""];
    id a = [PMKPromise pause:0.01].then(^{
        @throw @"NO";
    });
    id b = [PMKPromise pause:0.02];
    id c = [PMKPromise when:@[a, b]];
    [PMKPromise when:c].then(^{
        XCTFail();
    }).catch(^(NSError *e){
        XCTAssertEqualObjects(e.userInfo[PMKFailingPromiseIndexKey], @0);
        XCTAssertEqualObjects(e.userInfo[NSLocalizedDescriptionKey], @"NO");
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_22_already_resolved_and_bubble {
    id ex1 = [self expectationWithDescription:@""];
    id ex2 = [self expectationWithDescription:@""];

    __block void (^rejecter)(id) = nil;
    PMKPromise *promise = [PMKPromise new:^(id f, void (^r)(id)){
        rejecter = r;
    }];

    promise.then(^{
        XCTFail();
    }).catch(^(NSError *e){
        XCTAssertEqualObjects(e.localizedDescription, @"22");
        [ex1 fulfill];
    });

    rejecter(@22);

    [PMKPromise when:promise].then(^{
        XCTFail();
    }).catch(^{
        [ex2 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_23_add_another_fail_to_already_rejected {
    id ex1 = [self expectationWithDescription:@""];
    id ex2 = [self expectationWithDescription:@""];

    __block void (^rejecter)(id) = nil;

    PMKPromise *promise = [PMKPromise new:^(id f, id r){
        rejecter = r;
    }];

    promise.then(^{
        XCTFail();
    }).catch(^(NSError *e){
        XCTAssertEqualObjects(e.localizedDescription, @"23");
        [ex1 fulfill];
    });

    rejecter(@23);

    promise.then(^{
        XCTFail();
    }).catch(^(NSError *e){
        XCTAssertEqualObjects(e.localizedDescription, @"23");
        [ex2 fulfill];
    });
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_24_some_edge_case {
    id ex1 = [self expectationWithDescription:@""];
    id a = [PMKPromise pause:0.01].catch(^{});
    id b = [PMKPromise pause:0.02];
    [PMKPromise when:@[a, b]].then(^(NSArray *objs){
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_25_then_plus_deferred_plus_GCD {
    id ex1 = [self expectationWithDescription:@""];
    id ex2 = [self expectationWithDescription:@""];
    id ex3 = [self expectationWithDescription:@""];

    [PMKPromise pause:0.01].then(^(id o){
        [ex1 fulfill];
        return dispatch_promise(^{
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

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_26_promise_then_promise_fail_promise_fail {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise pause:0.01].then(^{
        return [PMKPromise pause:0.02].then(^{
            @throw @"1";
        }).catch(^{
            return [PMKPromise pause:0.01].then(^{
                @throw @"1";
            });
        });
    }).then(^{
        XCTFail();
    }).catch(^{
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];}

- (void)test_27_eat_failure {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise pause:0.01].then(^{
        @throw @"1";
    }).catch(^{
        return @YES;
    }).then(^{
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

PMKPromise *gcdreject() {
    return [PMKPromise new:^(id f, void(^rejecter)(id)){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                rejecter(nil);
            });
        });
    }];
}

- (void)test_28_deferred_rejected_catch_promise {
    id ex1 = [self expectationWithDescription:@""];

    gcdreject().catch(^{
        return [PMKPromise pause:0.01];
    }).then(^(id o){
        [ex1 fulfill];
    }).catch(^{
        XCTFail();
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_29_deferred_rejected_catch_promise {
    id ex1 = [self expectationWithDescription:@""];
    id ex2 = [self expectationWithDescription:@""];

    gcdreject().catch(^{
        [ex1 fulfill];
        return [PMKPromise pause:0.01].then(^{
            @throw @"1";
        });
    }).then(^{
        XCTFail(@"1");
    }).catch(^(NSError *error){
        [ex2 fulfill];
    }).catch(^{
        XCTFail(@"2");
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_30_dispatch_returns_pending_promise {
    id ex1 = [self expectationWithDescription:@""];
    dispatch_promise(^{
        return [PMKPromise pause:0.01];
    }).then(^{
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_31_dispatch_returns_promise {
    id ex1 = [self expectationWithDescription:@""];
    dispatch_promise(^{
        return [PMKPromise promiseWithValue:@1];
    }).then(^(id o){
        XCTAssertEqualObjects(o, @1);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_32_return_primitive {
    id ex1 = [self expectationWithDescription:@""];
    __block void (^fulfiller)(id) = nil;
    [PMKPromise new:^(id f, id r){
        fulfiller = f;
    }].then(^(id o){
        XCTAssertEqualObjects(o, @32);
        return 3;
    }).then(^(id o){
        XCTAssertEqualObjects(@3, o);
        [ex1 fulfill];
    });
    fulfiller(@32);
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_33_return_nil {
    id ex1 = [self expectationWithDescription:@""];
    [PMKPromise promiseWithValue:@1].then(^(id o){
        XCTAssertEqualObjects(o, @1);
        return nil;
    }).then(^{
        return nil;
    }).then(^(id o){
        XCTAssertNil(o);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_33a_return_nil {
    id ex1 = [self expectationWithDescription:@""];
    id ex2 = [self expectationWithDescription:@""];

    [PMKPromise promiseWithValue:@"HI"].then(^(id o){
        XCTAssertEqualObjects(o, @"HI");
        [ex1 fulfill];
        return nil;
    }).then(^{
        return nil;
    }).then(^{
        [ex2 fulfill];
        return nil;
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_34 {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise new:^(PMKFulfiller _fulfiller, id r){
        @throw @"1";
        _fulfiller(@2);
    }].then(^{
        XCTFail();
    }).catch(^(NSError *error){
        [ex1 fulfill];
        XCTAssertEqualObjects(error.localizedDescription, @"1");
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_35_when_nil {
    id ex1 = [self expectationWithDescription:@""];

    AnyPromise *promise = [PMKPromise promiseWithValue:@"35"].then(^{ return nil; });
    [PMKPromise when:@[[PMKPromise pause:0.01].then(^{ return @1; }), [PMKPromise promiseWithValue:nil], promise]].then(^(NSArray *results){
        XCTAssertEqual(results.count, 3ul);
        XCTAssertEqualObjects(results[1], [NSNull null]);
        [ex1 fulfill];
    }).catch(^(NSError *err){
        abort();
    });
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_36_promise_with_value_nil {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise promiseWithValue:nil].then(^(id o){
        XCTAssertNil(o);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_37_PMKMany_2 {
    id ex1 = [self expectationWithDescription:@""];

    dispatch_promise(^{
        return PMKManifold(@1, @2);
    }).then(^(id a, id b){
        XCTAssertEqualObjects(a, @1);
        XCTAssertEqualObjects(b, @2);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

// - (void)test_38_PMKMany_3 {
//     [NSURLConnection GET:URL].then(^(id data, id rsp, id originalData){
//         XCTAssertNotNil(data);
//         XCTAssertNotNil(rsp);
//         XCTAssertNotNil(originalData);
//         XCTAssertTrue([originalData isKindOfClass:NSData.class]);
//         XCTAssertTrue([data isKindOfClass:NSData.class]);
//         XCTAssertEqualObjects(data, originalData);
//         XCTAssertEqual(data, originalData);
//         resolved = YES;
//     });
//     wait(0.2);
//     XCTAssertTrue(resolved);
// }

- (void)test_39_when_with_some_values {
    id ex1 = [self expectationWithDescription:@""];

    id p = dispatch_promise(^{});
    id v = @1;
    [PMKPromise when:@[p, v]].then(^(NSArray *aa){
        XCTAssertEqual(aa.count, 2ul);
        XCTAssertEqualObjects(aa[1], @1);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_40_when_with_all_values {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise when:@[@1, @2]].then(^(NSArray *aa){
        XCTAssertEqualObjects(aa[0], @1);
        XCTAssertEqualObjects(aa[1], @2);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_41_when_with_repeated_promises {
    id ex1 = [self expectationWithDescription:@""];

    id p = dispatch_promise(^{});
    id v = @1;
    [PMKPromise when:@[p, v, p, v]].then(^(NSArray *aa){
        XCTAssertEqual(aa.count, 4ul);
        XCTAssertEqualObjects(aa[1], @1);
        XCTAssertEqualObjects(aa[3], @1);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_42 {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise promiseWithValue:@1].then(^{
        return dispatch_promise(^{});
    }).then(^{
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_43_return_promise_from_itself {
    id ex1 = [self expectationWithDescription:@""];

    PMKPromise *p = dispatch_promise(^{ return @1; });
    p.then(^{
        return p;
    }).then(^{
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_44_reseal {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise new:^(PMKFulfiller _fulfiller, id r){
        _fulfiller(@123);
        _fulfiller(@234);
    }].then(^(id o){
        XCTAssertEqualObjects(o, @123);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_45_when_which_returns_void {
    id ex1 = [self expectationWithDescription:@""];

    AnyPromise *promise = [PMKPromise promiseWithValue:@1].then(^{});
    [PMKPromise when:@[promise, [PMKPromise promiseWithValue:@1]]].then(^(NSArray *stuff){
        XCTAssertEqual(stuff.count, 2ul);
        XCTAssertEqualObjects(stuff[0], [NSNull null]);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}


- (void)test_46_test_then_on {
    id ex1 = [self expectationWithDescription:@""];

    dispatch_queue_t q1 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    dispatch_queue_t q2 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [PMKPromise promiseWithValue:@1].thenOn(q1, ^{
        XCTAssertFalse([NSThread isMainThread]);
        return dispatch_get_current_queue();
    }).thenOn(q2, ^(id q){
        XCTAssertFalse([NSThread isMainThread]);
        XCTAssertNotEqualObjects(q, dispatch_get_current_queue());
        [ex1 fulfill];
    });
#pragma clang diagnostic pop

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_47_finally_plus {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise promiseWithValue:@1].then(^{
        return @1;
    }).finally(^{
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_48_finally_negative {
    @autoreleasepool {
        id ex1 = [self expectationWithDescription:@""];
        id ex2 = [self expectationWithDescription:@""];

        PMKSetUnhandledErrorHandler(^(id e){
            [ex2 fulfill];
        });

        [PMKPromise promiseWithValue:@1].then(^{
            @throw @"1";
        }).finally(^{
            [ex1 fulfill];
        });
    }

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_49_finally_negative_later {
    id ex1 = [self expectationWithDescription:@""];
    __block int x = 0;

    [PMKPromise promiseWithValue:@1].then(^{
        XCTAssertEqual(++x, 1);
        @throw @"1";
    }).catch(^{
        XCTAssertEqual(++x, 2);
    }).then(^{
        XCTAssertEqual(++x, 3);
    }).finally(^{
        XCTAssertEqual(++x, 4);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_50_fulfill_with_pending_promise {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise new:^(void(^f)(id), id r){
        f([PMKPromise pause:0.01].then(^{ return @"HI"; }));
    }].then(^(id hi){
        XCTAssertEqualObjects(hi, @"HI");
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_51_fulfill_with_fulfilled_promise {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise new:^(void(^f)(id), id r){
        f([PMKPromise promiseWithValue:@1]);
    }].then(^(id o){
        XCTAssertEqualObjects(o, @1);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_52_fulfill_with_rejected_promise {
    id ex1 = [self expectationWithDescription:@""];
    dispatch_promise(^{
        return [PMKPromise new:^(void(^f)(id), id r){
            f([PMKPromise promiseWithValue:dummyError()]);
        }];
    }).catch(^(NSError *err){
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_53_return_rejected_promise {
    id ex1 = [self expectationWithDescription:@""];
    dispatch_promise(^{
        return @1;
    }).then(^{
        return [PMKPromise promiseWithValue:dummyError()];
    }).catch(^{
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_54_reject_with_rejected_promise {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise new:^(id f, void (^r)(id)){
        id err = [NSError errorWithDomain:@"a" code:123 userInfo:nil];
        r([PMKPromise promiseWithValue:err]);
    }].catch(^(NSError *err){
        XCTAssertEqual(err.code, 123);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_55_when_dictionary {
    id ex1 = [self expectationWithDescription:@""];

    id promises = @{
        @1: @2,
        @2: @"abc",
        @"a": [PMKPromise pause:0.01].then(^{ return @"HI"; })
    };
    [PMKPromise when:promises].then(^(NSDictionary *dict){
        XCTAssertEqual(dict.count, 3ul);
        XCTAssertEqualObjects(dict[@1], @2);
        XCTAssertEqualObjects(dict[@2], @"abc");
        XCTAssertEqualObjects(dict[@"a"], @"HI");
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_56_empty_array_when {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise when:@[]].then(^(NSArray *array){
        XCTAssertEqual(array.count, 0ul);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_58_just_finally {
    id ex1 = [self expectationWithDescription:@""];

    AnyPromise *promise = dispatch_promise(^{
        return nil;
    }).finally(^{
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];

    id ex2 = [self expectationWithDescription:@""];

    promise.finally(^{
        [ex2 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_59_typedef {
    id ex1 = [self expectationWithDescription:@""];

    PMKPromise *p1 = [PMKPromise promiseWithValue:@1];
    XCTAssertEqualObjects(p1.value, @1);

    p1.then(^(id o){
        XCTAssertEqualObjects(o, @1);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

//- (void)test_60_plain_new_is_rejected {
//    XCTAssertThrows([PMKPromise new]);
//    XCTAssertThrows([[PMKPromise alloc] init]);
//}

- (void)test_62_access_extra_elements {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise new:^(PMKFulfiller _fulfiller, id r){
        _fulfiller(PMKManifold(@1));
    }].then(^(id o, id m, id n){
        XCTAssertNil(m, @"Accessing extra elements should not crash");
        XCTAssertNil(n, @"Accessing extra elements should not crash");
        XCTAssertEqualObjects(o, @1);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_63_then_manifold {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise promiseWithValue:@0].then(^{
        return PMKManifold(@1, @2, @3);
    }).then(^(id o1, id o2, id o3){
        XCTAssertEqualObjects(o1, @1);
        XCTAssertEqualObjects(o2, @2);
        XCTAssertEqualObjects(o3, @3);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_63_then_manifold_with_nil {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise promiseWithValue:@0].then(^{
        return PMKManifold(@1, nil, @3);
    }).then(^(id o1, id o2, id o3){
        XCTAssertEqualObjects(o1, @1);
        XCTAssertEqualObjects(o2, nil);
        XCTAssertEqualObjects(o3, @3);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_64_catch_in_new {
    id ex1 = [self expectationWithDescription:@""];

    [PMKPromise new:^(id f, id r){
        @throw @"foo";
    }].catch(^{
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_65_manifold_fulfill_value {
    id ex1 = [self expectationWithDescription:@""];

    AnyPromise *promise = [PMKPromise promiseWithValue:@1].then(^{
        return PMKManifold(@123, @2);
    });

    promise.then(^(id a, id b){
        XCTAssertNotNil(a);
        XCTAssertNotNil(b);
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];

    XCTAssertEqualObjects(promise.value, @123);
}

- (void)test_66_until {
    id ex1 = [self expectationWithDescription:@""];

    __block BOOL this_happened = NO;
    __block int x = 0;
    [PMKPromise until:^{
        return dispatch_promise(^{
            if (x++ < 2)
                @throw @"no";
        });
    } catch:^(NSError *error){
        return dispatch_promise(^{
            this_happened = YES;
        });
    }].then(^{
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];

    XCTAssertTrue(this_happened);
}

- (void)test_67_until_failure {
    id ex1 = [self expectationWithDescription:@""];

    __block BOOL this_happened = NO;
    __block int x = 0;
    [PMKPromise until:^{
        return dispatch_promise(^{
            @throw @"no";
        });
    } catch:^(NSError *error){
        return dispatch_promise(^{
            this_happened = YES;
            if (x++ >= 2)
                @throw @"no";
        });
    }].then(^{
        XCTFail();
    }).catch(^{
        [ex1 fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:nil];

    XCTAssertTrue(this_happened);
}

- (void)test_68_unhandled_error_handler {
    @autoreleasepool {
        XCTestExpectation *ex = [self expectationWithDescription:@""];

        PMKSetUnhandledErrorHandler(^(NSError *error){
            XCTAssertEqualObjects(@"5", error.localizedDescription);
            [ex fulfill];
        });

        [PMKPromise new:^(id f, void (^r)(id)){
            r(@5);
        }];
    }
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_69_unhandled_handled_returned {
    @autoreleasepool {
        XCTestExpectation *ex1 = [self expectationWithDescription:@"unhandler"];
        XCTestExpectation *ex2 = [self expectationWithDescription:@"initial catch"];
        PMKSetUnhandledErrorHandler(^(NSError *error){
            XCTAssertEqualObjects(@"5", error.localizedDescription);
            [ex1 fulfill];
        });
        [PMKPromise new:^(id f, void (^r)(id)){
            r(@5);
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
    @autoreleasepool {
        XCTestExpectation *ex1 = [self expectationWithDescription:@""];

        PMKSetUnhandledErrorHandler(^(id err){
            XCTFail();
        });

        [PMKPromise new:^(id f, void (^r)(id)){
            r(@5);
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

- (void)test_72_reject_with_nil {
    XCTestExpectation *ex1 = [self expectationWithDescription:@""];
    [PMKPromise new:^(id f, void(^r)(id)){
        r(nil);
    }].catch(^{
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

//- (void)test_73_join {
//    XCTestExpectation *ex1 = [self expectationWithDescription:@""];
//    __block NSUInteger values = 0;
//    __block NSInteger errorCodes = 0;
//
//    __block void (^fulfiller)(id) = nil;
//    PMKPromise *promise =     [PMKPromise new:^(id f, id r){
//        fulfiller = f;
//    }];
//
//    [PMKPromise join:@[
//        [PMKPromise promiseWithValue:[NSError errorWithDomain:@"dom" code:1 userInfo:nil]],
//        promise,
//        [PMKPromise promiseWithValue:[NSError errorWithDomain:@"dom" code:2 userInfo:nil]]
//    ]].then(^(NSArray *successes, NSArray *errors) {
//        for (NSNumber *value in successes) {
//            values |= [value unsignedIntValue];
//        }
//        for (NSError *error in errors) {
//            errorCodes |= error.code;
//        }
//        [ex1 fulfill];
//    });
//    fulfiller(@4);
//    [self waitForExpectationsWithTimeout:2 handler:nil];
//    XCTAssertTrue(values == 4);
//    XCTAssertTrue(errorCodes == 3);
//}
//
//- (void)test_74_join_no_errors {
//    XCTestExpectation *ex1 = [self expectationWithDescription:@""];
//    __block NSArray *values = nil;
//    __block NSArray *errors = nil;
//    [PMKPromise join:@[
//        [PMKPromise promiseWithValue:@1],
//        [PMKPromise promiseWithValue:@2]
//    ]].then(^(NSArray *thenValues, NSArray *thenErrors) {
//        values = thenValues;
//        errors = thenErrors;
//        [ex1 fulfill];
//    });
//    [self waitForExpectationsWithTimeout:2 handler:nil];
//    XCTAssertEqualObjects(values, (@[@1, @2]));
//    XCTAssertFalse(errors);
//}
//
//- (void)test_75_join_no_success {
//    XCTestExpectation *ex1 = [self expectationWithDescription:@""];
//    __block NSArray *values = nil;
//    __block NSArray *errors = nil;
//    [PMKPromise join:@[
//        [PMKPromise promiseWithValue:[NSError errorWithDomain:@"dom" code:1 userInfo:nil]],
//        [PMKPromise promiseWithValue:[NSError errorWithDomain:@"dom" code:2 userInfo:nil]],
//    ]].then(^(NSArray *thenValues, NSArray *thenErrors) {
//        values = thenValues;
//        errors = thenErrors;
//        [ex1 fulfill];
//    });
//    [self waitForExpectationsWithTimeout:2 handler:nil];
//    XCTAssertEqualObjects(values, @[]);
//    XCTAssertTrue(errors);
//}

- (void)test_76_when_resolved_empty {
    XCTestExpectation *ex1 = [self expectationWithDescription:@""];
    [PMKPromise join:@[]].then(^(NSArray *successes, NSArray *errors) {
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_77_hang {
    __block int x = 0;
    id value = [PMKPromise hang:[PMKPromise pause:0.1].then(^{ x++; return 1; })];
    XCTAssertEqual(x, 1);
    XCTAssertEqualObjects(value, @1);
}

- (void)test_79_unhandled_error_handler_not_called_reject_passed_through {
    @autoreleasepool {
        XCTestExpectation *ex1 = [self expectationWithDescription:@""];

        PMKSetUnhandledErrorHandler(^(id e){
            XCTFail();
        });

        [PMKPromise new:^(void(^fulfill)(id), void(^reject)(id)){
            dispatch_promise(^{
                @throw @"1";
            }).catch(reject);
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

        PMKSetUnhandledErrorHandler(^(id e){
            XCTAssert(ex1Fulfilled);
            [ex2 fulfill];
        });

        [PMKPromise new:^(void(^fulfill)(id), void(^reject)(id)){
            dispatch_promise(^{
                @throw @"1";
            }).catch(reject);
        }].finally(^{
            [ex1 fulfill];
            ex1Fulfilled = YES;
        });
    }
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_properties {
    XCTAssertEqualObjects([PMKPromise promiseWithValue:@1].value, @1);
    XCTAssertEqual([[PMKPromise promiseWithValue:dummyWithCode(2)].value code], 2);
    XCTAssertTrue([PMKPromise promiseWithResolverBlock:^(id a){}].pending);
    XCTAssertFalse([PMKPromise promiseWithResolverBlock:^(id a){}].resolved);
    XCTAssertFalse([PMKPromise promiseWithValue:@1].pending);
    XCTAssertTrue([PMKPromise promiseWithValue:@1].resolved);
}

@end


@interface WTF2Error : NSError @end
@implementation WTF2Error @end


@implementation PMKPromiseTestSuite (More)

- (void)test_999_allow_error_subclasses {
    XCTestExpectation *ex1 = [self expectationWithDescription:@""];
    
    dispatch_promise(^{
        return [WTF2Error errorWithDomain:@"WTF" code:0 userInfo:nil];
    }).catch(^(NSError *e){
        XCTAssertEqualObjects(e.class, WTF2Error.class);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

@end
