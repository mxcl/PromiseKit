#import <Foundation/NSEnumerator.h>
#import <PromiseKit/Promise.h>


@interface PMKPromise (Join)
/**
 Creates a new promise that resolves only when all provided promises have resolved.

 Typically, you should use `+when:`.

 @param promises An array of promises.

 @return A promise that thens two parameters:

 1) An array of values from the promises that fulfilled.
 2) An array of errors from the promises that rejected or nil if all promises fulfilled.

 This promise is not rejectable.

 @warning *Important* It is not possible to know which promises fulfilled and which rejected.

     pod "PromiseKit/join"

 @see when
*/
+ (PMKPromise *)join:(NSArray *)promises;

@end
