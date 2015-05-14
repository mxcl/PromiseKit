#import <PromiseKit/PromiseKit.h>
#import "UIActionSheet+AnyPromise.h"


@interface PMKActionSheetDelegate : NSObject <UIActionSheetDelegate> {
@public
    id retainCycle;
    PMKResolver resolve;
}
@end


@implementation PMKActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        resolve([NSError cancelledError]);
    } else {
        resolve(PMKManifold(@(buttonIndex), actionSheet));
    }
    retainCycle = nil;
}

@end


@implementation UIActionSheet (PromiseKit)

- (AnyPromise *)promiseInView:(UIView *)view {
    PMKActionSheetDelegate *d = [PMKActionSheetDelegate new];
    d->retainCycle = self.delegate = d;
    [self showInView:view];
    return [[AnyPromise alloc] initWithResolver:&d->resolve];
}

@end
