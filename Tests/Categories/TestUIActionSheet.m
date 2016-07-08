#import "UIActionSheet+AnyPromise.h"
@import PromiseKit;
@import XCTest;
@import UIKit;

@implementation Test_UIActionSheet_Objc : XCTestCase {
    UIViewController *rootvc;
}

- (void)setUp {
    rootvc = [UIApplication sharedApplication].keyWindow.rootViewController = [UIViewController new];
}

- (void)tearDown {
    [UIApplication sharedApplication].keyWindow.rootViewController = nil;
}

// fulfills with buttonIndex
- (void)test1 {
    id ex = [self expectationWithDescription:@""];

    UIActionSheet *sheet = [UIActionSheet new];
    [sheet addButtonWithTitle:@"0"];
    [sheet addButtonWithTitle:@"1"];
    sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"2"];
    [sheet promiseInView:rootvc.view].then(^(id obj){
        XCTAssertEqual([obj integerValue], 1);
        [ex fulfill];
    });
    PMKAfter(0.1).then(^{
        [sheet dismissWithClickedButtonIndex:1 animated: NO];
    });
    [self waitForExpectationsWithTimeout:10 handler: nil];
}

// cancel button presses are cancelled errors
- (void)test2 {
    id ex = [self expectationWithDescription:@""];

    UIActionSheet *sheet = [UIActionSheet new];
    [sheet addButtonWithTitle:@"0"];
    [sheet addButtonWithTitle:@"1"];
    sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"2"];
    [sheet promiseInView:rootvc.view].catchWithPolicy(PMKCatchPolicyAllErrors, ^(NSError *err){
        XCTAssertTrue(err.isCancelled);
        [ex fulfill];
    });
    PMKAfter(0.1).then(^{
        [sheet dismissWithClickedButtonIndex:2 animated: NO];
    });
    [self waitForExpectationsWithTimeout:10 handler: nil];
}

// single button UIActionSheets don't get considered cancelled
- (void)test3 {
    id ex = [self expectationWithDescription:@""];

    UIActionSheet *sheet = [UIActionSheet new];
    [sheet addButtonWithTitle:@"0"];
    [sheet promiseInView:rootvc.view].then(^(id obj){
        XCTAssertEqual([obj integerValue], 0);
        [ex fulfill];
    });
    PMKAfter(0.1).then(^{
        [sheet dismissWithClickedButtonIndex:0 animated: NO];
    });
    [self waitForExpectationsWithTimeout:10 handler: nil];
}

// single button UIActionSheets don't get considered cancelled unless the cancelIndex is set
- (void)test4 {
    id ex = [self expectationWithDescription:@""];

    UIActionSheet *sheet = [UIActionSheet new];
    sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"0"];
    [sheet promiseInView:rootvc.view].catchWithPolicy(PMKCatchPolicyAllErrors, ^(NSError *err){
        XCTAssertTrue(err.isCancelled);
        [ex fulfill];
    });
    PMKAfter(0.1).then(^{
        [sheet dismissWithClickedButtonIndex:0 animated: NO];
    });
    [self waitForExpectationsWithTimeout:10 handler: nil];
}

@end
