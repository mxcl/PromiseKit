#import <PromiseKit/PromiseKit.h>
#import "UIAlertView+AnyPromise.h"
@import UIKit;
@import XCTest;

@implementation Test_UIAlertView_ObjC: XCTestCase

// fulfills with buttonIndex
- (void)test1 {
    id ex = [self expectationWithDescription:@""];

    UIAlertView *alert = [UIAlertView new];
    [alert addButtonWithTitle:@"0"];
    [alert addButtonWithTitle:@"1"];
    alert.cancelButtonIndex = [alert addButtonWithTitle:@"2"];
    [alert promise].then(^(id obj){
        XCTAssertEqual([obj integerValue], 1);
        [ex fulfill];
    });
    PMKAfter(0.5).then(^{
        [alert dismissWithClickedButtonIndex:1 animated: NO];
    });
    [self waitForExpectationsWithTimeout:3 handler: nil];
}

// cancel button presses are cancelled errors
- (void)test2 {
    id ex = [self expectationWithDescription:@""];

    UIAlertView *alert = [UIAlertView new];
    [alert addButtonWithTitle:@"0"];
    [alert addButtonWithTitle:@"1"];
    alert.cancelButtonIndex = [alert addButtonWithTitle:@"2"];
    [alert promise].catchWithPolicy(PMKCatchPolicyAllErrors, ^(NSError *err){
        XCTAssertTrue(err.cancelled);
        [ex fulfill];
    });
    PMKAfter(0.5).then(^{
        [alert dismissWithClickedButtonIndex:2 animated: NO];
    });
    [self waitForExpectationsWithTimeout:3 handler: nil];
}

// single button UIAlertViews don't get considered cancelled
- (void)test3 {
    id ex = [self expectationWithDescription:@""];

    UIAlertView *alert = [UIAlertView new];
    [alert addButtonWithTitle:@"0"];
    [alert promise].then(^{
        [ex fulfill];
    });
    PMKAfter(0.5).then(^{
        [alert dismissWithClickedButtonIndex:0 animated: NO];
    });
    [self waitForExpectationsWithTimeout:3 handler: nil];
}

// single button UIAlertViews don't get considered cancelled unless the cancelIndex is set
- (void)test4 {
    id ex = [self expectationWithDescription:@""];

    UIAlertView *alert = [UIAlertView new];
    alert.cancelButtonIndex = [alert addButtonWithTitle:@"0"];
    [alert promise].catchWithPolicy(PMKCatchPolicyAllErrors, ^(NSError *err){
        [ex fulfill];
    });
    PMKAfter(0.5).then(^{
        [alert dismissWithClickedButtonIndex:0 animated: NO];
    });
    [self waitForExpectationsWithTimeout:3 handler: nil];
}

@end
