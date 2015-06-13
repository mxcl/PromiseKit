#import <Bolts/BFTask.h>
#import <dispatch/queue.h>
#import <PromiseKit/AnyPromise.h>


@interface BFTask (AnyPromise)

- (AnyPromise *(^)(id))then;
- (AnyPromise *(^)(dispatch_queue_t, id))thenOn;

/**
 Any object that provides this function can be spliced into any PromiseKit chain.
*/
- (AnyPromise *)pmk_adapt;

@end
