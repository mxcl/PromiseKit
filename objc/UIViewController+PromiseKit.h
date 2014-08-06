#import <PromiseKit/fwd.h>
#import <UIKit/UIViewController.h>

@interface UIViewController (PromiseKit)

/**
 Calls `presentViewController:` such that the presentedViewController can
 call `reject:` or `fulfill:` and resolve the promise. When resolved the
 presentedViewController is dismissed.

 This method is smart and SDK provided ViewControllers like
 `MFMailComposeViewController` will be automatically delegate into the
 returned Promise.
 */
- (PMKPromise *)promiseViewController:(UIViewController *)vc animated:(BOOL)animated completion:(void(^)(void))block NS_AVAILABLE_IOS(5_0);

- (void)fulfill:(id)result;
- (void)reject:(NSError *)error;

- (PMKPromise *)promiseSegueWithIdentifier:(NSString*) identifier sender:(id) sender NS_AVAILABLE_IOS(5_0);

@end
