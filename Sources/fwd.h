#import <Foundation/NSDate.h>
#import <dispatch/dispatch.h>

@class AnyPromise;
extern NSString * __nonnull const PMKErrorDomain;

#define PMKFailingPromiseIndexKey @"PMKFailingPromiseIndexKey"
#define PMKJoinPromisesKey @"PMKJoinPromisesKey"

#define PMKUnexpectedError 1l
#define PMKInvalidUsageError 3l
#define PMKAccessDeniedError 4l
#define PMKOperationFailed 8l
#define PMKTaskError 9l
#define PMKJoinError 10l
#define PMKNoWinnerError 11l


#ifdef __cplusplus
extern "C" {
#endif

/**
 @return A new promise that resolves after the specified duration.

 @parameter duration The duration in seconds to wait before this promise is resolve.

 For example:

    PMKAfter(1).then(^{
        //…
    });
*/
extern AnyPromise * __nonnull PMKAfter(NSTimeInterval duration) NS_REFINED_FOR_SWIFT;



/**
 `when` is a mechanism for waiting more than one asynchronous task and responding when they are all complete.

 `PMKWhen` accepts varied input. If an array is passed then when those promises fulfill, when’s promise fulfills with an array of fulfillment values. If a dictionary is passed then the same occurs, but when’s promise fulfills with a dictionary of fulfillments keyed as per the input.

 Interestingly, if a single promise is passed then when waits on that single promise, and if a single non-promise object is passed then when fulfills immediately with that object. If the array or dictionary that is passed contains objects that are not promises, then these objects are considered fulfilled promises. The reason we do this is to allow a pattern know as "abstracting away asynchronicity".

 If *any* of the provided promises reject, the returned promise is immediately rejected with that promise’s rejection. The error’s `userInfo` object is supplemented with `PMKFailingPromiseIndexKey`.

 For example:

    PMKWhen(@[promise1, promise2]).then(^(NSArray *results){
        //…
    });

 @warning *Important* In the event of rejection the other promises will continue to resolve and as per any other promise will either fulfill or reject. This is the right pattern for `getter` style asynchronous tasks, but often for `setter` tasks (eg. storing data on a server), you most likely will need to wait on all tasks and then act based on which have succeeded and which have failed. In such situations use `PMKJoin`.

 @param input The input upon which to wait before resolving this promise.

 @return A promise that is resolved with either:

  1. An array of values from the provided array of promises.
  2. The value from the provided promise.
  3. The provided non-promise object.

 @see PMKJoin

*/
extern AnyPromise * __nonnull PMKWhen(id __nonnull input) NS_REFINED_FOR_SWIFT;



/**
 Creates a new promise that resolves only when all provided promises have resolved.

 Typically, you should use `PMKWhen`.

 For example:

    PMKJoin(@[promise1, promise2]).then(^(NSArray *resultingValues){
        //…
    }).catch(^(NSError *error){
        assert(error.domain == PMKErrorDomain);
        assert(error.code == PMKJoinError);

        NSArray *promises = error.userInfo[PMKJoinPromisesKey];
        for (AnyPromise *promise in promises) {
            if (promise.rejected) {
                //…
            }
        }
    });

 @param promises An array of promises.

 @return A promise that thens three parameters:

  1) An array of mixed values and errors from the resolved input.
  2) An array of values from the promises that fulfilled.
  3) An array of errors from the promises that rejected or nil if all promises fulfilled.

 @see when
*/
AnyPromise *__nonnull PMKJoin(NSArray * __nonnull promises) NS_REFINED_FOR_SWIFT;



/**
 Literally hangs this thread until the promise has resolved.
 
 Do not use hang… unless you are testing, playing or debugging.
 
 If you use it in production code I will literally and honestly cry like a child.
 
 @return The resolved value of the promise.

 @warning T SAFE. IT IS NOT SAFE. IT IS NOT SAFE. IT IS NOT SAFE. IT IS NO
*/
extern id __nullable PMKHang(AnyPromise * __nonnull promise);



/**
 Executes the provided block on a background queue.

 dispatch_promise is a convenient way to start a promise chain where the
 first step needs to run synchronously on a background queue.

    dispatch_promise(^{
        return md5(input);
    }).then(^(NSString *md5){
        NSLog(@"md5: %@", md5);
    });

 @param block The block to be executed in the background. Returning an `NSError` will reject the promise, everything else (including void) fulfills the promise.

 @return A promise resolved with the return value of the provided block.

 @see dispatch_async
*/
extern AnyPromise * __nonnull dispatch_promise(id __nonnull block) NS_SWIFT_UNAVAILABLE("Use our `DispatchQueue.async` override instead");



/**
 Executes the provided block on the specified background queue.

    dispatch_promise_on(myDispatchQueue, ^{
        return md5(input);
    }).then(^(NSString *md5){
        NSLog(@"md5: %@", md5);
    });

 @param block The block to be executed in the background. Returning an `NSError` will reject the promise, everything else (including void) fulfills the promise.

 @return A promise resolved with the return value of the provided block.

 @see dispatch_promise
*/
extern AnyPromise * __nonnull dispatch_promise_on(dispatch_queue_t __nonnull queue, id __nonnull block) NS_SWIFT_UNAVAILABLE("Use our `DispatchQueue.async` override instead");

/**
 Returns a new promise that resolves when the value of the first resolved promise in the provided array of promises.
*/
extern AnyPromise * __nonnull PMKRace(NSArray * __nonnull promises) NS_REFINED_FOR_SWIFT;

/**
 Returns a new promise that resolves with the value of the first fulfilled promise in the provided array of promises.
*/
extern AnyPromise * __nonnull PMKRaceFulfilled(NSArray * __nonnull promises) NS_REFINED_FOR_SWIFT;

#ifdef __cplusplus
}   // Extern C
#endif
