#import <PromiseKit/fwd.h>
#import <UIKit/UIAlertView.h>

@interface UIAlertView (PromiseKit)
/**
 Thens the dismissedButtonIndex and the alertView itself as the second
 parameter. This promise will never be rejected.
 */
- (PMKPromise *)promise;
@end
