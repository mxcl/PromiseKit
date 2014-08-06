#import <objc/runtime.h>
#import "PromiseKit/Promise.h"
#import "UIActionSheet+PromiseKit.h"


@interface PMKActionSheetDelegater : NSObject <UIActionSheetDelegate> {
@public
    void (^fulfiller)(id);
}
@end


@implementation PMKActionSheetDelegater

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    fulfiller(PMKManifold(@(buttonIndex), actionSheet));
    PMKRelease(self);
}

@end


@implementation UIActionSheet (PromiseKit)

- (PMKPromise *)promiseInView:(UIView *)view {
    PMKActionSheetDelegater *d = [PMKActionSheetDelegater new];
    PMKRetain(d);
    self.delegate = d;
    [self showInView:view];
    return [PMKPromise new:^(id fulfiller, id rejecter){
        d->fulfiller = fulfiller;
    }];
}

@end
