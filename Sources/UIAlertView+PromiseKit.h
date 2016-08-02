#import <PromiseKit/fwd.h>
#import <UIKit/UIAlertView.h>

/**
 To import the `UIAlertView` category:

    pod "PromiseKit/UIAlertView"

 Or you can import all categories on `UIKit`:

    pod "PromiseKit/UIKit"

 Or `UIKit` is one of the categories imported by the umbrella pod:

    pod "PromiseKit"
*/
@interface UIAlertView (PromiseKit)

/**
 Displays the alert view.

 @return A promise the fulfills with two parameters:
 1) The index of the button that was tapped to dismiss the alert.
 2) This alert view.
*/
- (PMKPromise *)promise;

@end
