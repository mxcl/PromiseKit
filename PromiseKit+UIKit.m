#import "Private/macros.m"
#import "PromiseKit/Deferred.h"
#import "PromiseKit/Promise.h"
#import "PromiseKit+UIKit.h"
@import UIKit.UINavigationController;

@interface PMKMFDeferred : Deferred
@end

@implementation PMKMFDeferred

- (void)mailComposeController:(id)controller didFinishWithResult:(int)result error:(NSError *)error {
    if (error)
        [self reject:error];
    else
        [self resolve:@(result)];

    __anti_arc_release(self);
}
@end



@implementation UIViewController (PromiseKit)

- (Promise *)promiseViewController:(UIViewController *)vc animated:(BOOL)animated completion:(void(^)(void))block
{
    [self presentViewController:vc animated:animated completion:block];

    Deferred *d = [Deferred new];

    if ([vc isKindOfClass:NSClassFromString(@"MFMailComposeViewController")]) {
        d = [PMKMFDeferred new];
        __anti_arc_retain(d);
        SEL selector = NSSelectorFromString(@"setMailComposeDelegate:");
        IMP imp = [vc methodForSelector:selector];
        void (*func)(id, SEL, id) = (void *)imp;
        func(vc, selector, d);
    } else {
        if ([vc isKindOfClass:[UINavigationController class]])
            vc = [(id)vc viewControllers].firstObject;
        SEL viewWillDefer = NSSelectorFromString(@"viewWillDefer:");
        if ([vc respondsToSelector:viewWillDefer]) {
            IMP imp = [vc methodForSelector:viewWillDefer];
            void (*func)(id, SEL, Deferred *) = (void *)imp;
            func(vc, viewWillDefer, d);
        } else
            NSLog(@"You didn't implement viewWillDefer:! You should do that.");
    }

    return d.promise.then(^(id o){
        [self dismissViewControllerAnimated:animated completion:nil];
        return o;
    });
}

@end



@interface PMKAlertViewDelegate : Deferred <UIAlertViewDelegate>
@end

@implementation PMKAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [self resolve:@(buttonIndex)];
    __anti_arc_release(self);
}
@end

@implementation UIAlertView (PromiseKit)

- (Promise *)promise {
    PMKAlertViewDelegate *d = [PMKAlertViewDelegate new];
    __anti_arc_retain(d);
    self.delegate = d;
    [self show];
    return d.promise;
}

@end




@interface PMKActionSheetDelegate : Deferred <UIActionSheetDelegate>
@end

@implementation PMKActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [self resolve:@(buttonIndex)];
    __anti_arc_release(self);
}
@end

@implementation UIActionSheet (PromiseKit)

- (Promise *)promiseInView:(UIView *)view {
    PMKActionSheetDelegate *d = [PMKActionSheetDelegate new];
    __anti_arc_retain(d);
    self.delegate = d;
    [self showInView:view];
    return d.promise;
}

@end
