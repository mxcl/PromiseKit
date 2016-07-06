#import <dispatch/dispatch.h>

static dispatch_once_t __PMKDefaultDispatchQueueToken;
static dispatch_queue_t __PMKDefaultDispatchQueue;

dispatch_queue_t PMKDefaultDispatchQueue() {
    dispatch_once(&__PMKDefaultDispatchQueueToken, ^{
        if (__PMKDefaultDispatchQueue == nil) {
            __PMKDefaultDispatchQueue = dispatch_get_main_queue();
        }
    });
    return __PMKDefaultDispatchQueue;
}

void PMKSetDefaultDispatchQueue(dispatch_queue_t newDefaultQueue) {
    dispatch_once(&__PMKDefaultDispatchQueueToken, ^{
        __PMKDefaultDispatchQueue = newDefaultQueue;
    });
}
