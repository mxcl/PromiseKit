#import <PromiseKit/Promise.h>


@interface PMKPromise (Pause)

/**
 Pauses the chain by the specified number of seconds.

 Pipes the value from the parent promise to child promises. The second `then`
 value is the `duration` of the pause.
*/
- (PMKPromise *(^)(NSTimeInterval))pause;

/**
 Returns a new promise that fulfills with @p `duration` after `duration`
 seconds have passed. Internally uses `dispatch_after`.
*/
+ (PMKPromise *)pause:(NSTimeInterval)duration;

@end
