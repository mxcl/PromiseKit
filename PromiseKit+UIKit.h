@import UIKit.UIViewController;
@import UIKit.UIAlertView;
@import UIKit.UIActionSheet;
@class Promise;
@class Deferred;



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

 Important: you need to implement viewWillDefer: in your presentedViewController
 in order to get the Deferred object that controls the presentation.
*/
- (Promise *)promiseViewController:(UIViewController *)vc animated:(BOOL)animated completion:(void(^)(void))block;

@end



@interface UIAlertView (PromiseKit)
- (Promise *)promise;
@end



@interface UIActionSheet (PromiseKit)
- (Promise *)promiseInView:(UIView *)view;
@end
