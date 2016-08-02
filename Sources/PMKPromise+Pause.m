#import "PromiseKit/Promise+Pause.h"

#define Queue dispatch_get_main_queue()


@implementation PMKPromise (Pause)

- (PMKPromise *(^)(NSTimeInterval))pause {
    return ^(NSTimeInterval delay) {
        return self.then(^(id value){
            return [self.class new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
                dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
                dispatch_after(time, Queue, ^{
                    fulfiller(PMKManifold(value ?: @(delay), @(delay)));
                });
            }];
        });
    };
}

+ (PMKPromise *)pause:(NSTimeInterval)delay {
    return [self new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
        dispatch_after(time, Queue, ^{
            fulfiller(@(delay));
        });
    }];
}

@end
