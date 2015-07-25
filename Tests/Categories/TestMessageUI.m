@import MessageUI;
@import UIKit;
#import "UIViewController+AnyPromise.h"
@import XCTest;


#if 0  // not possible to test these in the simulator

@implementation Test_MessageUI_ObjC: XCTestCase {
    UIViewController *rootvc;
}

- (void)setUp {
    rootvc = [UIApplication sharedApplication].keyWindow.rootViewController = [UIViewController new];
}

- (void)tearDown {
    rootvc = [UIApplication sharedApplication].keyWindow.rootViewController = nil;
}

- (void)testCanCancelMailComposeViewController {
    id ex = [self expectationWithDescription:@""];

    MFMailComposeViewController *mf = [MFMailComposeViewController new];

    [mf setToRecipients:@[@"mxcl@me.com"]];

    [rootvc promiseViewController:mf animated:NO completion:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIBarButtonItem *button = [mf.viewControllers[0] navigationItem].leftBarButtonItem;

            ((void (*)(id, SEL))[button.target methodForSelector:button.action])(button.target, button.action);
        });
    }].catchWithPolicy(PMKCatchPolicyAllErrors, ^{
        [ex fulfill];
    });

    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testCanCancelMessageComposeViewController {
    id ex = [self expectationWithDescription:@""];

    MFMessageComposeViewController *mf = [MFMessageComposeViewController new];

    [rootvc promiseViewController:mf animated:NO completion:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIBarButtonItem *button = [mf.viewControllers[0] navigationItem].leftBarButtonItem;

            ((void (*)(id, SEL))[button.target methodForSelector:button.action])(button.target, button.action);
        });
    }].catchWithPolicy(PMKCatchPolicyAllErrors, ^{
        [ex fulfill];
    });

    [self waitForExpectationsWithTimeout:10 handler:nil];
}

@end

#endif
