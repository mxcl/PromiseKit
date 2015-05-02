#import <PromiseKit/PromiseKit.h>
#import "UIAlertView+AnyPromise.h"


@interface PMKAlertViewDelegate : NSObject <UIAlertViewDelegate> {
@public
    PMKResolver resolve;
    id retainCycle;
}
@end


@implementation PMKAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        resolve(PMKManifold(@(buttonIndex), alertView));
    } else {
        resolve([NSError cancelledError]);
    }
    retainCycle = nil;
}

@end


@implementation UIAlertView (PromiseKit)

- (AnyPromise *)promise {
    PMKAlertViewDelegate *d = [PMKAlertViewDelegate new];
    d->retainCycle = self.delegate = d;
    [self show];
    return [AnyPromise promiseWithResolver:&d->resolve];
}

@end
