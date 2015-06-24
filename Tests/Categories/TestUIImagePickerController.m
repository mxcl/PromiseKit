@import KIF;
#import <PromiseKit/PromiseKit.h>
@import UIKit;
#import "UIViewController+AnyPromise.h"
@import XCTest;

@interface TestAnyPromiseImagePickerController: XCTestCase
@end

@implementation TestAnyPromiseImagePickerController {
    UIViewController *rootvc;
}

- (void)setUp {
    rootvc = [UIApplication sharedApplication].keyWindow.rootViewController = [UIViewController new];
}

- (void)tearDown {
    [UIApplication sharedApplication].keyWindow.rootViewController = nil;
}

static NSArray *allSubviews(UIView *root) {
    NSMutableArray *vv = root.subviews.mutableCopy;
    for (UIView *subview in root.subviews)
        [vv addObjectsFromArray:allSubviews(subview)];
    return vv;
}

static id find(UIView *root, id type) {
    for (id x in allSubviews(root))
        if ([x isKindOfClass:type])
            return x;
    NSLog(@"%@", allSubviews(root));
    return nil;
}

// it fulfills with a UIImage
- (void)test1 {
    id ex = [self expectationWithDescription:@""];
    UIImagePickerController *picker = [UIImagePickerController new];

    [rootvc promiseViewController:picker animated:NO completion:^{
        PMKAfter(0.5).then(^{
            UITableView *tv = find(picker.view, [UITableView class]);
            [tv.visibleCells[1] tap];
            return PMKAfter(1.5);
        }).then(^{
            id vcs = picker.viewControllers;
            id cv = find([vcs[1] view], UICollectionView.class);
            id cell = [cv visibleCells][0];
            [cell tap];
        });
    }].then(^(UIImage *image){
        XCTAssertGreaterThan(image.size.width, 0);
        [ex fulfill];
    });

    [self waitForExpectationsWithTimeout:10 handler:nil];
}

// it can be cancelled
- (void)test2 {
    id ex = [self expectationWithDescription:@""];
    UIImagePickerController *picker = [UIImagePickerController new];

    [rootvc promiseViewController:picker animated:NO completion:^{
        PMKAfter(0.5).then(^{
            UIBarButtonItem *button = [picker.viewControllers[0] navigationItem].rightBarButtonItem;
            ((void (*)(id, SEL))[button.target methodForSelector:button.action])(button.target, button.action);
        });
    }].catchWithPolicy(PMKCatchPolicyAllErrors, ^(NSError *error){
        [ex fulfill];
    });

    [self waitForExpectationsWithTimeout:10 handler:nil];
}

@end
