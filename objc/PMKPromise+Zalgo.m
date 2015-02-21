#import "PromiseKit/Promise.h"
#import "PromiseKit/Promise+Zalgo.h"
extern id pmk_safely_call_block(id block, id result);


PMKPromise *dispatch_zalgo(id block) {
    if (NSThread.isMainThread) {
        return dispatch_promise(block);
    } else {
        id value = pmk_safely_call_block(block, nil);
        return [PMKPromise promiseWithValue:value];
    }
}


@implementation PMKPromise (Zalgo)

- (PMKPromise *(^)(id))thenUnleashZalgo {
    if (self.pending) {
        return [self then];
    } else {
        return ^(id block){
            id value = pmk_safely_call_block(block, self.value);
            return [PMKPromise promiseWithValue:value];
        };
    }
}

@end
