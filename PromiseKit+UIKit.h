@import UIKit.UIViewController;
@import UIKit.UIAlertView;
@import UIKit.UIActionSheet;
@class PMKPromise;



@interface UIViewController (PromiseKit)

/**
 .2.4.6.8.0.2.4.6.8.0.2.4.6.8.0.2.4.6.8.0.2.4.6.8.0.2.4.6.8.0.2.4.6.8.0.2
 Calls `presentViewController:` such that the presentedViewController can
 call `reject:` or `fulfill:` and resolve the promise. When resolved the
 presentedViewController is dismissed.

 This method is smart and SDK provided ViewControllers like
 `MFMailComposeViewController` will be automatically delegate into the
 returned Promise.
 */
- (PMKPromise *)promiseViewController:(UIViewController *)vc animated:(BOOL)animated completion:(void(^)(void))block;

- (void)fulfill:(id)result;
- (void)reject:(NSError *)error;

@end



@interface UIAlertView (PromiseKit)
/**
 Thens the dismissedButtonIndex and the alertView itself as the second
 parameter. This promise can not be rejected.
 */
- (PMKPromise *)promise;
@end



@interface UIActionSheet (PromiseKit)
/**
 Thens the dismissedButtonIndex and the actionSheet itself as the second
 parameter. This promise can not be rejected.
 */
- (PMKPromise *)promiseInView:(UIView *)view;
@end
