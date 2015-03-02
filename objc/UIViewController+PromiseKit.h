#import <PromiseKit/fwd.h>
#import <UIKit/UIViewController.h>

/**
 To import the `UIViewController` category:

    pod "PromiseKit/UIViewController"

 Or you can import all categories on `UIKit`:

    pod "PromiseKit/UIKit"

 Or `UIKit` is one of the categories imported by the umbrella pod:

    pod "PromiseKit"
*/
@interface UIViewController (PromiseKit)

/**
 Presents a view controller modally.

 Calls `presentViewController:` such that the presentedViewController can
 call `reject:` or `fulfill:` and resolve the promise. When resolved the
 presentedViewController is dismissed.

 PromiseKit goes the extra mile and automatically handles the delegation
 or completion handlers for the following CocoaTouch view controllers:

  - MFMailComposeViewController
  - UIImagePickerController
  - SLComposeViewController

 @return A promise that can be fulfilled by the presented view controller.
 */
- (PMKPromise *)promiseViewController:(UIViewController *)vc animated:(BOOL)animated completion:(void(^)(void))block NS_AVAILABLE_IOS(5_0);

/**
 View controllers presented with promiseViewController:animated:completion:
 can call this method to dismiss themselves and fulfill the promise they
 were presented with.
*/
- (void)fulfill:(id)result;

/**
 View controllers presented with promiseViewController:animated:completion:
 can call this method to dismiss themselves and reject the promise they
 were presented with.
*/
- (void)reject:(NSError *)error;

- (PMKPromise *)promiseSegueWithIdentifier:(NSString*) identifier sender:(id) sender NS_AVAILABLE_IOS(5_0) PMK_DEPRECATED("This method is considered unsafe and will be removed.");

@end
