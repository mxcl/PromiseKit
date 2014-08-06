#import <Foundation/NSEnumerator.h>
#import <PromiseKit/Promise.h>


@interface PMKPromise (When)
/**
Returns a new Promise that is resolved when all passed Promises are resolved.

If an array is passed then the returned `Promise` is resolved once all of the `Promise`s in the array are resolved. The returned Promise is rejected immediately if *any* of the `Promise`s received by `when` fail, discarding all other Promise values (thus you only get one error in any catch handler you provide).

The returned `Promise` is resolved with an array of results indexed as the original array passed to when. If you pass a single value to when, you will not get an array in subsequent `then`s.

@param promiseOrArrayOfPromisesOrValue an array of Promises, a single Promise or a single value of any type.
*/
+ (PMKPromise *)when:(id)promiseOrArrayOfPromisesOrValue;

/**
 Same as when, though only takes an object that implements `NSFastEnumeration` (`NSArray` implements `NSFastEnumeration`)

 Alias provided due to ES6 specifications.
*/
+ (PMKPromise *)all:(id<NSFastEnumeration, NSObject>)enumerable;

@end
