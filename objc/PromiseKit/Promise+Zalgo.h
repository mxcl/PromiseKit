#import <PromiseKit/fwd.h>

/**
 Executes block immediately if we are not on the main thread. Otherwise
 dispatches to the default background queue first.

 Do not use this function unless you understand the implications of
 unleashing zalgo!

 This function is provided mainly as an optimization tool for *libraries*
 that provide promises. Typically, it is not worth the risk to use this
 function in your own code, the performance gains are negligible relative
 to the risk of damaging the integrity of your asynchronous logic.
*/
PMKPromise *dispatch_zalgo(id block);



@interface PMKPromise (Zalgo)

/**
 Executes the block immediately if the promise is already resolved.
 Otherwise behaves like `then`.

 Do not use this function unless you understand the implications of
 unleashing zalgo!

 @see -then
 @see dispatch_zalgo
*/
- (PMKPromise *(^)(id))thenUnleashZalgo;

@end
