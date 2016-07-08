@import Foundation;
@import PromiseKit;
#import "Infrastructure.h"

AnyPromise *PMKDummyAnyPromise_YES() {
    return [AnyPromise promiseWithValue:@YES];
}

AnyPromise *PMKDummyAnyPromise_Manifold() {
    return [AnyPromise promiseWithValue:PMKManifold(@YES, @NO, @NO)];
}

AnyPromise *PMKDummyAnyPromise_Error() {
    return [AnyPromise promiseWithValue:[NSError errorWithDomain:@"a" code:1 userInfo:nil]];
}

@implementation PromiseBridgeHelper (objc)

- (AnyPromise *)bridge2 {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            resolve(@123);
        });
    }];
}

@end
