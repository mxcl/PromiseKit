#import <Foundation/NSEnumerator.h>
#import <PromiseKit/Promise.h>


@interface PMKPromise (Join)
/**
Returns a new Promise that is resolved only when all passed Promises are resolved.

The returned `Promise` is resolved once all of the `Promise`s in the array are resolved (either rejected or fulfilled). Unlike `+when`, the returned `Promise` is not rejected immediately if one of the promises in the array are rejected. In fact, it is never rejected, even if all the promises in the array were.

The promise will resolve to a pair `NSArray *fulfilledResults, NSArray *rejectedErrors`. If no promises were rejected, `rejectedErrors` will be `nil`.

@param promises an array of Promises.
*/
+ (PMKPromise *)join:(NSArray*)promises;

@end
