@import UIKit;
@import XCTest;
#import <PromiseKit/PromiseKit.h>
#import "UIViewController+AnyPromise.h"


@interface MyViewController: UIViewController
@property AnyPromise *promise;
@end
@implementation MyViewController
@end


@implementation Test_UIViewController_ObjC: XCTestCase {
    UIViewController *rootvc;
}

- (void)setUp {
    rootvc = [UIApplication sharedApplication].keyWindow.rootViewController = [UIViewController new];
}

- (void)tearDown {
    [UIApplication sharedApplication].keyWindow.rootViewController = nil;
}

// view controller is presented and dismissed when promise is resolved
- (void)test1 {
    id ex = [self expectationWithDescription:@""];

    PMKResolver resolve;

    MyViewController *myvc = [MyViewController new];
    myvc.promise = [[AnyPromise alloc] initWithResolver:&resolve];
    [rootvc promiseViewController:myvc animated:NO completion:nil].then(^{
        // seems to take another tick for the dismissal to complete
    }).then(^{
        [ex fulfill];
    });

    XCTAssertNotNil(rootvc.presentedViewController);

    PMKAfter(1).then(^{
        resolve(@1);
    });

    [self waitForExpectationsWithTimeout:10 handler:nil];

    XCTAssertNil(rootvc.presentedViewController);
}

// view controller is not presented if promise is resolved
- (void)test2 {
    MyViewController *myvc = [MyViewController new];
    myvc.promise = [AnyPromise promiseWithValue:nil];
    [rootvc promiseViewController:myvc animated:NO completion:nil];

    XCTAssertNil(rootvc.presentedViewController);
}

// promise property must be promise
- (void)test3 {
    id ex = [self expectationWithDescription:@""];

    MyViewController *myvc = [MyViewController new];
    myvc.promise = (id) @1;
    [rootvc promiseViewController:myvc animated:NO completion:nil].catch(^(id err){
        [ex fulfill];
    });

    XCTAssertNil(rootvc.presentedViewController);

    [self waitForExpectationsWithTimeout:10 handler:nil];

    XCTAssertNil(rootvc.presentedViewController);
}

// promise property must not be nil
- (void)test4 {
    id ex = [self expectationWithDescription:@""];

    MyViewController *myvc = [MyViewController new];
    [rootvc promiseViewController:myvc animated:NO completion:nil].catch(^(id err){
        [ex fulfill];
    });

    XCTAssertNil(rootvc.presentedViewController);

    [self waitForExpectationsWithTimeout:10 handler:nil];

    XCTAssertNil(rootvc.presentedViewController);
}

// view controller must have a promise property
- (void)test5 {
    id ex = [self expectationWithDescription:@""];

    UIViewController *vc = [UIViewController new];
    [rootvc promiseViewController:vc animated:NO completion:nil].catch(^(id err){
        [ex fulfill];
    });

    XCTAssertNil(rootvc.presentedViewController);

    [self waitForExpectationsWithTimeout:10 handler:nil];

    XCTAssertNil(rootvc.presentedViewController);
}

// promised nav controllers use their root vc’s promise property
- (void)test6 {
    id ex = [self expectationWithDescription:@""];

    PMKResolver resolve;

    MyViewController *myvc = [MyViewController new];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:myvc];
    myvc.promise = [[AnyPromise alloc] initWithResolver:&resolve];
    [rootvc promiseViewController:nc animated:NO completion:nil].then(^(id obj){
        XCTAssertEqualObjects(@1, obj);
    }).then(^{
        [ex fulfill];
    });

    XCTAssertNotNil(rootvc.presentedViewController);

    PMKAfter(1).then(^{
        resolve(@1);
    });

    [self waitForExpectationsWithTimeout:10 handler:nil];

    XCTAssertNil(rootvc.presentedViewController);
}

@end
