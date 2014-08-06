#import <PromiseKit/fwd.h>
#import <UIKit/UIActionSheet.h>

@interface UIActionSheet (PromiseKit)
/**
 Thens the dismissedButtonIndex and the actionSheet itself as the second
 parameter. This promise will never be rejected.
 */
- (PMKPromise *)promiseInView:(UIView *)view;
@end
