#import <objc/runtime.h>
#import <PromiseKit/Promise.h>
#import "UIAlertView+PromiseKit.h"


@interface PMKAlertViewDelegater : NSObject <UIAlertViewDelegate> {
@public
    void (^fulfiller)(id);
}
@end


@implementation PMKAlertViewDelegater

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    fulfiller(PMKManifold(@(buttonIndex), alertView));
    PMKRelease(self);
}

@end


@implementation UIAlertView (PromiseKit)

- (PMKPromise *)promise {
    PMKAlertViewDelegater *d = [PMKAlertViewDelegater new];
    PMKRetain(d);
    self.delegate = d;
    [self show];
    return [PMKPromise new:^(id fulfiller, id rejecter){
        d->fulfiller = fulfiller;
    }];
}

@end
