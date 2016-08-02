#import <AssetsLibrary/AssetsLibrary.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <PromiseKit/Promise.h>
#import <UIKit/UIStoryboardSegue.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UIImagePickerController.h>
#import "UIViewController+PromiseKit.h"

static const char *kSegueFulfiller = "kSegueFulfiller";
static const char *kSegueRejecter = "kSegueRejecter";

@interface PMKMFDelegater : NSObject
@end

@interface PMKUIImagePickerControllerDelegate : NSObject <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@end


@implementation UIViewController (PromiseKit)

- (PMKPromise *)promiseViewController:(UIViewController *)vc animated:(BOOL)animated completion:(void(^)(void))block
{
    [self presentViewController:vc animated:animated completion:block];

    if ([vc isKindOfClass:NSClassFromString(@"MFMailComposeViewController")]) {
        PMKMFDelegater *delegater = [PMKMFDelegater new];
        PMKRetain(delegater);

        SEL selector = NSSelectorFromString(@"setMailComposeDelegate:");
        IMP imp = [vc methodForSelector:selector];
        void (*func)(id, SEL, id) = (void *)imp;
        func(vc, selector, delegater);
    }
    else if ([vc isKindOfClass:NSClassFromString(@"MFMessageComposeViewController")]) {
        PMKMFDelegater *delegater = [PMKMFDelegater new];
        PMKRetain(delegater);

        SEL selector = NSSelectorFromString(@"setMessageComposeDelegate:");
        IMP imp = [vc methodForSelector:selector];
        void (*func)(id, SEL, id) = (void *)imp;
        func(vc, selector, delegater);
    }
    else if ([vc isKindOfClass:NSClassFromString(@"UIImagePickerController")]) {
        PMKUIImagePickerControllerDelegate *delegator = [PMKUIImagePickerControllerDelegate new];
        PMKRetain(delegator);
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

static void classOverridingSelector(const char* newClassPrefix, id target, SEL originalSelector, SEL overrideSelector) {
    Class klass = [target class];
    NSString *className = NSStringFromClass(klass);
    
    if (strncmp(newClassPrefix, [className UTF8String], strlen(newClassPrefix)) != 0) {
        NSString* subclassName = [NSString stringWithFormat:@"%s%@", newClassPrefix, className];
        Class subclass = NSClassFromString(subclassName);
        if (subclass == nil) {
            subclass = objc_allocateClassPair(klass, [subclassName UTF8String], 0);
            if (subclass != nil) {
                objc_registerClassPair(subclass);
                Method swizzledMethod = class_getInstanceMethod(klass, overrideSelector);
                BOOL methodAdded = class_addMethod(subclass, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
                if (!methodAdded)
                    @throw @"Swizzle failure.";
            }
        }
        if (subclass != nil) {
            object_setClass(target, subclass);
        }
    }
}

#define _PMKS(x) #x
#define PMKPrefix _PMKS(PromiseKitUIKit_)
#define PMKPrefixify(x) PromiseKitUIKit_##x

- (PMKPromise *)promiseSegueWithIdentifier:(NSString *)identifier sender:(id) sender {
    return [PMKPromise new:^(id fulfiller, id rejecter){
        classOverridingSelector(PMKPrefix, self, @selector(prepareForSegue:sender:), @selector(PMKPrefixify(prepareForSegue:sender:)));

        objc_setAssociatedObject(self, kSegueFulfiller, fulfiller, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(self, kSegueRejecter, rejecter, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        [self performSegueWithIdentifier:identifier sender:sender];
    }].finally(^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

- (void)PMKPrefixify(prepareForSegue):(UIStoryboardSegue *)segue sender:(id)sender {    
    id fulfiller = objc_getAssociatedObject(segue.sourceViewController, kSegueFulfiller);
    id rejecter = objc_getAssociatedObject(segue.sourceViewController, kSegueRejecter);

    objc_setAssociatedObject(self, kSegueFulfiller, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, kSegueRejecter, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);    
    objc_setAssociatedObject(segue.destinationViewController, @selector(fulfill:), fulfiller, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(segue.destinationViewController, @selector(reject:), rejecter, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    Class zuper = class_getSuperclass([self class]);
    SEL prepareForSegueSelector = @selector(prepareForSegue:sender:);
    if ([zuper instancesRespondToSelector:prepareForSegueSelector]) {
        struct objc_super objcSuper;
        objcSuper.receiver = self;
        objcSuper.super_class = zuper;
        ((void(*)(id, SEL, id, id))objc_msgSendSuper)((__bridge id)(&objcSuper), prepareForSegueSelector, segue, sender);
    }
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



@implementation PMKMFDelegater

- (void)mailComposeController:(id)controller didFinishWithResult:(int)result error:(NSError *)error {
    if (error)
        [controller reject:error];
    else
        [controller fulfill:@(result)];

    PMKRelease(self);
}

- (void)messageComposeViewController:(id)controller didFinishWithResult:(int)result {
    if (result == 2)
        [controller reject:[NSError errorWithDomain:PMKErrorDomain code:PMKOperationFailed userInfo:@{NSLocalizedDescriptionKey: @"The user’s attempt to save or send the message was unsuccessful."}]];
    else
        [controller fulfill:@(result)];

    PMKRelease(self);
}

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
        PMKRelease(self);
    }
    failureBlock:^(NSError *error){
        [picker reject:error];
        PMKRelease(self);
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker fulfill:nil];
    PMKRelease(self);
}

@end
