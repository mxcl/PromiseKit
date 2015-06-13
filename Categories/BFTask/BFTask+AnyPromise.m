#import "BFTask+AnyPromise.h"
#import <PromiseKit/PromiseKit.h>


@implementation BFTask (AnyPromise)

static inline AnyPromise *BFThen(BFTask *task, dispatch_queue_t queue, id block) {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [task continueWithBlock:^id(BFTask *task) {
            if (task.cancelled) {
                resolve([NSError cancelledError]);
            }
            if (task.exception) {
                // maybe shouldn't, probably bolts uses more exceptions than we expect
                @throw task.exception;
            }
            resolve(task.error ?: task.result);
            return nil;
        }];
    }].thenOn(queue, block);
}

- (AnyPromise *(^)(id))then {
    return ^(id block) {
        return BFThen(self, dispatch_get_main_queue(), block);
    };
}

- (AnyPromise *(^)(dispatch_queue_t, id))thenOn {
    return ^(dispatch_queue_t queue, id block) {
        return BFThen(self, queue, block);
    };
}

@end
