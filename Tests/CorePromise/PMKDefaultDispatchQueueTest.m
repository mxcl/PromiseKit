//
//  PMKDefaultDispatchQueue.test.m
//  PromiseKit
//
//  Created by David Rodriguez on 4/14/16.
//  Copyright © 2016 Max Howell. All rights reserved.
//

#import <PromiseKit/AnyPromise.h>
@import XCTest;

@interface PMKDefaultDispatchQueueTest : XCTestCase @end @implementation PMKDefaultDispatchQueueTest

- (void)tearDown {
    [super tearDown];
    
    PMKDefaultDispatchQueue = ^ {
        return dispatch_get_main_queue();
    };
}

- (void) testThenWithDefaultQueue {
    __block BOOL fulfilled = NO;
    XCTestExpectation *testExpectation = [self expectationWithDescription:@"resolving"];
    
    AnyPromise *promise = [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        resolve(@1);
    }];
    promise.then(^(NSNumber *o){
        fulfilled = YES;
        [testExpectation fulfill];
    });
    promise.catch(^{
        XCTFail();
    });
    
    XCTAssertFalse(fulfilled);
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError * _Nullable error) {
        XCTAssertTrue(fulfilled);
    }];
}

- (void) testThenWithDifferentQueue {
    
    __block dispatch_queue_t q1 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    
    PMKDefaultDispatchQueue = ^ {
        return q1;
    };
    
    __block BOOL resolved = NO;
    XCTestExpectation *testExpectation = [self expectationWithDescription:@"resolving"];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    AnyPromise *promise = [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        resolve(@1);
    }];
    promise.then(^(NSNumber *o){
        XCTAssertFalse([NSThread isMainThread]);
        XCTAssertEqualObjects(q1, dispatch_get_current_queue());
        
        resolved = YES;
        [testExpectation fulfill];
    });
    promise.catch(^{
        XCTFail();
    });
#pragma clang diagnostic pop
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError * _Nullable error) {
        XCTAssertTrue(resolved);
    }];
}

- (void) testCatchWithDefaultQueue {
    __block BOOL resolved = NO;
    XCTestExpectation *testExpectation = [self expectationWithDescription:@"resolving"];
    
    AnyPromise *promise = [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        resolve([NSError errorWithDomain:@"test" code:0 userInfo:nil]);
    }];
    promise.then(^(NSNumber *o){
        XCTFail();
    });
    promise.catch(^{
        resolved = YES;
        [testExpectation fulfill];
    });
    
    XCTAssertFalse(resolved);
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError * _Nullable error) {
        XCTAssertTrue(resolved);
    }];
}

- (void) testCatchWithDifferentQueue {
    
    __block dispatch_queue_t q1 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    
    PMKDefaultDispatchQueue = ^ {
        return q1;
    };
    
    __block BOOL resolved = NO;
    XCTestExpectation *testExpectation = [self expectationWithDescription:@"resolving"];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    AnyPromise *promise = [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        resolve([NSError errorWithDomain:@"test" code:0 userInfo:nil]);
    }];
    promise.then(^(NSNumber *o){
        XCTFail();
    });
    promise.catch(^{
        XCTAssertFalse([NSThread isMainThread]);
        XCTAssertEqualObjects(q1, dispatch_get_current_queue());
        
        resolved = YES;
        [testExpectation fulfill];
    });
#pragma clang diagnostic pop
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError * _Nullable error) {
        XCTAssertTrue(resolved);
    }];
}

- (void) testFinallyWithDefaultQueue {
    __block BOOL fulfilled = NO;
    XCTestExpectation *testExpectation = [self expectationWithDescription:@"resolving"];
    
    AnyPromise *promise = [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        resolve(@1);
    }];
    promise.finally(^(){
        fulfilled = YES;
        [testExpectation fulfill];
    });
    
    XCTAssertFalse(fulfilled);
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError * _Nullable error) {
        XCTAssertTrue(fulfilled);
    }];
}

- (void) testFinallyWithDifferentQueue {
    
    __block dispatch_queue_t q1 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    
    PMKDefaultDispatchQueue = ^ {
        return q1;
    };
    
    __block BOOL resolved = NO;
    XCTestExpectation *testExpectation = [self expectationWithDescription:@"resolving"];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    AnyPromise *promise = [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        resolve(@1);
    }];
    promise.finally(^(){
        XCTAssertFalse([NSThread isMainThread]);
        XCTAssertEqualObjects(q1, dispatch_get_current_queue());
        
        resolved = YES;
        [testExpectation fulfill];
    });
#pragma clang diagnostic pop
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError * _Nullable error) {
        XCTAssertTrue(resolved);
    }];
}

@end