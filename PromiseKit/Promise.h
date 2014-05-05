@import Foundation.NSObject;


typedef void (^PromiseResolver)(id);

/**
A `Promise` represents the future value of a task.

To obtain the value of a `Promise`, call `then`. When the asynchronous task that this `Promise` represents has resolved successfully, the block you pass to `then` will be executed with the resolved value. If the `Promise` has already been resolved succesfully at the time you `then` the `Promise`, the block will be executed immediately.

Effective use of Promises involves chaining `then`s, where the return value from one `then` is fed as the value of the next, et cetera.

For a thorough overview of Promises, @see http://promisekit.org
*/
@interface Promise : NSObject

/**
The pattern of Promises is defined by the method: `then`.

Provide a block to `then`, your block may take one or no arguments, and return an object or have no return value. We use block introspection to provide such flexibility.

Returning from your block will resolve the next `Promise` with that value.

If an exception is thrown inside your block, or you return an `NSError` object the next `Promise` will be rejected. @see `catch` for documentation on error handling.

@return A new `Promise` to be executed after the block passed to this `then`
*/
- (Promise *(^)(id))then;


- (Promise *(^)(id))catch;

/**
Returns a new Promise that is resolved when all passed Promises are resolved.

If an array is passed then the returned `Promise` is resolved once all of the `Promise`s in the array are resolved. The returned Promise is rejected if *any* of the `Promise`s received by `when` fail.

The returned `Promise` is resolved with an array of results indexed as the original array passed to when. If you pass a single value to when, you will not get an array in subsequent `then`s.

Any `catch` handler will be called with a single `NSError` where the `PMKThrown` key of its `userInfo` will be an array of results. The results usually is a mixed array of `NSError`s and non-errors since usually not all the `Promise`s fail.

@param promiseOrArrayOfPromisesOrValue an array of Promises, a single Promise or a single value of any type.
*/
+ (Promise *)when:(id)promiseOrArrayOfPromisesOrValue;

/**
Loops until one or more promises have resolved.

Because Promises are single-shot, the block to until must return one or more promises. They are then `when`’d. If they succeed the until loop is concluded. If they fail then the @param `catch` handler is executed.

If the `catch` throws or returns an `NSError` then the loop is ended.

If the `catch` handler returns a Promise then re-execution of the loop is suspended upon resolution of that Promise. If the Promise succeeds then the loop continues. If it fails the loop ends.

An example usage is an app starting up that must get data from the Internet before the main ViewController can be shown. You can `until` the poll Promise and in the catch handler decide if the poll should be reattempted or not, perhaps returning a `UIAlertView.promise` allowing the user to choose if they continue or not.
*/
+ (Promise *)until:(id(^)(void))blockReturningPromiseOrArrayOfPromises catch:(id)catchHandler;

/**
 Create a new root Promise.

 Pass a block to this constructor, the block must take two arguments that point to the `fulfiller` and `rejecter` of this Promise. Fulfill or reject this Promise using those blocks and the Promise chain that roots to this Promise will be resolved accordingly.
*/
+ (Promise *)new:(void(^)(PromiseResolver fulfiller, PromiseResolver rejecter))block;

/** 
@return A new `Promise` that is already resolved with @param value. Calling `then` on a resolved `Promise` executes the provided block immediately.
*/
+ (Promise *)promiseWithValue:(id)value;
@end



/**
 Use with `[Promise new:]` to fulfill a Promise with multiple arguments.

 Consumers of your Promise are not compelled to consume any arguments and
 in fact will often only consume the first parameter. Thus ensure the
 order of parameters is: from most-important to least-important.

 Note that attempts to reject with `PMKMany` will `@throw`.
*/
id PMKManifold(NSArray *arguments);
#define PMKManifold(...) PMKManifold(@[__VA_ARGS__])



#define PMKErrorDomain @"PMKErrorDomain"
#define PMKThrown @"PMKThrown"
#define PMKErrorCodeThrown 1
#define PMKErrorCodeUnknown 2
#define PMKErrorCodeInvalidUsage 3



/**
Executes @param block via `dispatch_async` with `DISPATCH_QUEUE_PRIORITY_DEFAULT`.

The returned `Promise` is resolved with the value returned from @param block (if any). Any `then` or `catch` attached to the returned `Promise` is exectued on the main queue.

@param block A block to be executed in the background.
@return A new `Promise` to be executed after @param block.
*/
Promise *dispatch_promise(id block);



@import Dispatch.queue;

/**
 Executes @param block via `dispatch_async` on the specified queue.
 @see dispatch_promise
 */
Promise *dispatch_promise_on(dispatch_queue_t q, id block);
