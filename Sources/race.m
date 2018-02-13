#import "AnyPromise+Private.h"

AnyPromise *PMKRace(NSArray *promises) {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        for (AnyPromise *promise in promises) {
            [promise __pipe:resolve];
        }
    }];
}
