#import <PromiseKit/AnyPromise.h>
#import <UIKit/UIAlertView.h>

/**
 To import the `UIAlertView` category:

    use_frameworks!
    pod "PromiseKit/UIKit"

 Or `UIKit` is one of the categories imported by the umbrella pod:

    use_frameworks!
    pod "PromiseKit"

 And then in your sources:

    #import <PromiseKit/PromiseKit.h>
*/
@interface UIAlertView (PromiseKit)

/**
 Displays the alert view.

    UIAlertView *alert = [UIAlertView new];
    alert.title = @"OHAI";
    [alert addButtonWithTitle:@"OK"];
    [alert promise].then(^(NSNumber *dismissedButtonIndex){
        //…
    });

 @return A promise the fulfills with two parameters:

  1) The index of the button that was tapped to dismiss the alert.
  2) This alert view.
*/
- (AnyPromise *)promise;

@end
