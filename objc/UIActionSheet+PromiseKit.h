#import <PromiseKit/fwd.h>
#import <UIKit/UIActionSheet.h>

/**
 To import the `UIActionSheet` category:

    pod "PromiseKit/UIActionSheet"

 Or you can import all categories on `UIKit`:

    pod "PromiseKit/UIKit"

 Or `UIKit` is one of the categories imported by the umbrella pod:

    pod "PromiseKit"
*/
@interface UIActionSheet (PromiseKit)

/**
 Displays the action sheet originating from the specified view.

 @param view The view from which the action sheet originates.

 @return A promise the fulfills with two parameters:
 1) The index of the button that was tapped to dismiss the sheet.
 2) This action sheet.
*/
- (PMKPromise *)promiseInView:(UIView *)view;

@end
