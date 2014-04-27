@import UIKit.UIViewController;
@import UIKit.UIAlertView;
@import UIKit.UIActionSheet;
@class Promise;



@interface UIViewController (PromiseKit)

/**
 Presents with a promise.

 When you resolve the controller’s deferred we will dismiss the controller
 the dismissal will occur when the promise is resolved, so if you need
 the dismissal of the controller to occur later, instead chain another
 promise before resolving this deferred.
 
 Bonus!
 
 We detect MFMailComposeViewControllers and automatically convert the
 mailComposeDelegate into a promise.
 
 We should handle any other speciality controllers also, but we may
 require you submit those as pull requests.
*/
- (Promise *)promiseViewController:(UIViewController *)vc animated:(BOOL)animated completion:(void(^)(void))block;

- (void)fulfill:(id)result;
- (void)reject:(NSError *)error;

@end



@interface UIAlertView (PromiseKit)
- (Promise *)promise;
@end



@interface UIActionSheet (PromiseKit)
- (Promise *)promiseInView:(UIView *)view;
@end
