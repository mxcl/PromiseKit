#import <AssetsLibrary/AssetsLibrary.h>
#import <objc/runtime.h>
#import "Private/PMKManualReference.h"
#import "Private/ClassSwizzling.m"
#import "PromiseKit/Promise.h"
@import UIKit.UINavigationController;
@import UIKit.UIImagePickerController;
#import "UIKit+PromiseKit.h"

static const char *kSegueFulfiller = "kSegueFulfiller";
static const char *kSegueRejecter = "kSegueRejecter";

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

@interface PMKUIImagePickerControllerDelegate : NSObject <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@end

@implementation PMKUIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    id img = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
    id url = info[UIImagePickerControllerReferenceURL];

    [[ALAssetsLibrary new] assetForURL:url resultBlock:^(ALAsset *asset) {
        NSUInteger const N = (NSUInteger)asset.defaultRepresentation.size;
        uint8_t *bytes = malloc(N);
        [asset.defaultRepresentation getBytes:bytes fromOffset:0 length:N error:nil];
        id data = [NSData dataWithBytes:bytes length:N];
        free(bytes);

        [picker fulfill:PMKManifold(img, data, info)];
        [self pmk_breakReference];
    }
    failureBlock:^(NSError *error){
        [picker reject:error];
        [self pmk_breakReference];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker fulfill:nil];
    [self pmk_breakReference];
}

@end



@implementation UIViewController (PromiseKit)

- (PMKPromise *)promiseViewController:(UIViewController *)vc animated:(BOOL)animated completion:(void(^)(void))block
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
    else if ([vc isKindOfClass:NSClassFromString(@"UIImagePickerController")]) {
        PMKUIImagePickerControllerDelegate *delegator = [PMKUIImagePickerControllerDelegate new];
        [delegator pmk_reference];
        [(UIImagePickerController *)vc setDelegate:delegator];
    }
    else if ([vc isKindOfClass:NSClassFromString(@"SLComposeViewController")]) {
        return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
            id block = ^(int result){
                fulfiller(@(result));
                [self dismissViewControllerAnimated:animated completion:nil];
            };
            [vc setValue:block forKey:@"completionHandler"];
        }];
    }
    else if ([vc isKindOfClass:[UINavigationController class]])
        vc = [(id)vc viewControllers].firstObject;
    
    if (!vc) {
        id err = [NSError errorWithDomain:PMKErrorDomain code:PMKInvalidUsageError userInfo:@{NSLocalizedDescriptionKey: @"Cannot promise a `nil` viewcontroller"}];
        return [PMKPromise promiseWithValue:err];
    }
    
    return [PMKPromise new:^(id fulfiller, id rejecter){
        objc_setAssociatedObject(vc, @selector(fulfill:), fulfiller, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(vc, @selector(reject:), rejecter, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }].finally(^{
        [self dismissViewControllerAnimated:animated completion:nil];
    });
}

- (PMKPromise *)promiseSegueWithIdentifier:(NSString*) identifier sender:(id) sender {
    
    const char* prefix = "PromiseKitUIKitSegue_";
    swizzleClass(prefix, self, @selector(prepareForSegue:sender:), @selector(PromiseKitUIKit_prepareForSegue:sender:));
    PMKPromise* promise = [PMKPromise new:^(id fulfiller, id rejecter){
        objc_setAssociatedObject(self,
                                 kSegueFulfiller,
                                 fulfiller,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(self,
                                 kSegueRejecter,
                                 rejecter,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }].finally(^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
    
    [self performSegueWithIdentifier:identifier sender:sender];
    return promise;
}


-(void) PromiseKitUIKit_prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    id fulfiller = objc_getAssociatedObject(segue.sourceViewController, kSegueFulfiller);
    id rejecter = objc_getAssociatedObject(segue.sourceViewController, kSegueRejecter);
    objc_setAssociatedObject(self, kSegueFulfiller, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, kSegueRejecter, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    
    objc_setAssociatedObject(segue.destinationViewController, @selector(fulfill:), fulfiller, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(segue.destinationViewController, @selector(reject:), rejecter, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    
    [self PromiseKitUIKit_prepareForSegue:segue sender:sender];
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

- (PMKPromise *)promise {
    PMKAlertViewDelegater *d = [PMKAlertViewDelegater new];
    [d pmk_reference];
    self.delegate = d;
    [self show];
    return [PMKPromise new:^(id fulfiller, id rejecter){
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

- (PMKPromise *)promiseInView:(UIView *)view {
    PMKActionSheetDelegater *d = [PMKActionSheetDelegater new];
    [d pmk_reference];
    self.delegate = d;
    [self showInView:view];
    return [PMKPromise new:^(id fulfiller, id rejecter){
        d->fulfiller = fulfiller;
    }];
}

@end
