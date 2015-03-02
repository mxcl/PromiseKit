#import <Foundation/NSEnumerator.h>
#import <PromiseKit/Promise.h>


@interface PMKPromise (When)
/**
Returns a new promise that is fulfilled if and when all the provided promises are fulfilled.

@param promiseOrArrayOfPromisesOrValue The input upon which to wait before resolving this promise.

If an array is passed then the returned promise is fulfilled once all the provided promises are fulfilled. If *any* of the provided promises reject, the returned promise is immediately rejected with that promise’s rejection error.

@return A promise that is resolved with either:
1. An array of values from the provided array of promises.
2. The value from the provided promise.
3. The provided non-promise object.

Note that passing an `NSError` to when will reject the returned promise.
*/
+ (PMKPromise *)when:(id)promiseOrArrayOfPromisesOrValue;

/**
 Alias for `+when:` provided due to ES6 specifications.

 @see when
*/
+ (PMKPromise *)all:(id<NSFastEnumeration, NSObject>)enumerable;

@end
