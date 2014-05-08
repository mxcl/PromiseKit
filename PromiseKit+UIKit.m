#import <objc/runtime.h>
#import "Private/PMKManualReference.h"
#import "PromiseKit/Promise.h"
#import "PromiseKit+UIKit.h"
@import UIKit.UINavigationController;

@interface PMKMFDelegater : NSObject
@end

@implementation PMKMFDelegater

- (void)mailComposeController:(id)controller didFinishWithResult:(int)result error:(NSError *)error {
    if (error)
        [controller reject:error];
    else
        [controller fulfill:@(result)];

    [self pmk_breakReference];
}
@end



@implementation UIViewController (PromiseKit)

- (Promise *)promiseViewController:(UIViewController *)vc animated:(BOOL)animated completion:(void(^)(void))block
{
    [self presentViewController:vc animated:animated completion:block];

    if ([vc isKindOfClass:NSClassFromString(@"MFMailComposeViewController")]) {
        PMKMFDelegater *delegater = [PMKMFDelegater new];

        [delegater pmk_reference];

        SEL selector = NSSelectorFromString(@"setMailComposeDelegate:");
        IMP imp = [vc methodForSelector:selector];
        void (*func)(id, SEL, id) = (void *)imp;
        func(vc, selector, delegater);
    }
    else if ([vc isKindOfClass:[UINavigationController class]])
        vc = [(id)vc viewControllers].firstObject;
    
    if (!vc) {
        id err = [NSError errorWithDomain:PMKErrorDomain code:PMKErrorCodeInvalidUsage userInfo:@{NSLocalizedDescriptionKey: @"Cannot promise a `nil` viewcontroller"}];
        return [Promise promiseWithValue:err];
    }
    
    return [Promise new:^(id fulfiller, id rejecter){
        objc_setAssociatedObject(vc, @selector(fulfill:), fulfiller, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(vc, @selector(reject:), rejecter, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }].then(^(id o){
        [self dismissViewControllerAnimated:animated completion:nil];
        return o;
    });
}

- (void)fulfill:(id)result {
    void (^fulfiller)(id) = objc_getAssociatedObject(self, _cmd);
    fulfiller(result);
}

- (void)reject:(NSError *)error {
    void (^rejecter)(id) = objc_getAssociatedObject(self, _cmd);
    rejecter(error);
}

@end



@interface PMKAlertViewDelegater : NSObject <UIAlertViewDelegate> {
@public
    void (^fulfiller)(id);
}
@end

@implementation PMKAlertViewDelegater
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    fulfiller(PMKManifold(@(buttonIndex), alertView));
    [self pmk_breakReference];
}
@end

@implementation UIAlertView (PromiseKit)

- (Promise *)promise {
    PMKAlertViewDelegater *d = [PMKAlertViewDelegater new];
    [d pmk_reference];
    self.delegate = d;
    [self show];
    return [Promise new:^(id fulfiller, id rejecter){
        d->fulfiller = fulfiller;
    }];
}

@end




@interface PMKActionSheetDelegater : NSObject <UIActionSheetDelegate> {
@public
    void (^fulfiller)(id);
}
@end

@implementation PMKActionSheetDelegater
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    fulfiller(PMKManifold(@(buttonIndex), actionSheet));
    [self pmk_breakReference];
}
@end

@implementation UIActionSheet (PromiseKit)

- (Promise *)promiseInView:(UIView *)view {
    PMKActionSheetDelegater *d = [PMKActionSheetDelegater new];
    [d pmk_reference];
    self.delegate = d;
    [self showInView:view];
    return [Promise new:^(id fulfiller, id rejecter){
        d->fulfiller = fulfiller;
    }];
}

@end
