#import <dispatch/dispatch.h>
#import <Foundation/NSError.h>
#import <Foundation/NSArray.h>
#import <PromiseKit/fwd.h>

/**
A `Promise` represents the future value of a task.

To obtain the value of a `Promise`, call `then`. When the asynchronous task that this `Promise` represents has resolved successfully, the block you pass to `then` will be executed with the resolved value. If the `Promise` has already been resolved succesfully at the time you `then` the `Promise`, the block will be executed immediately.

Effective use of Promises involves chaining `then`s, where the return value from one `then` is fed as the value of the next, et cetera.

For a thorough overview of Promises, @see http://promisekit.org
*/
@interface PMKPromise : NSObject

/**
The pattern of Promises is defined by the method: `then`.

Provide a block to `then`, your block may take one or no arguments, and return an object or have no return value. We use block introspection to provide such flexibility.

Returning from your block will resolve the next `Promise` with that value.

If an exception is thrown inside your block, or you return an `NSError` object the next `Promise` will be rejected. @see `catch` for documentation on error handling.

Then is always executed on the main dispatch queue (i.e the main/UI thread).

@see `-thenOn`

@return A new `Promise` to be executed after the block passed to this `then`
*/
- (PMKPromise *(^)(id))then;

/**
 The provided block always runs on the main queue.
*/
- (PMKPromise *(^)(id))catch;

/**
 The provided block always runs on the main queue.
*/
- (PMKPromise *(^)(void(^)(void)))finally;

/**
 The provided block is executed on the dispatch queue of your choice.
*/
- (PMKPromise *(^)(dispatch_queue_t, id))thenOn;

/**
 The provided block is executed on the dispatch queue of your choice.
*/
- (PMKPromise *(^)(dispatch_queue_t, id))catchOn;

/**
 The provided block is executed on the dispatch queue of your choice.
*/
- (PMKPromise *(^)(dispatch_queue_t, void(^)(void)))finallyOn;

/** 
@return A new `Promise` that is already resolved with @param value. Calling `then` on a resolved `Promise` executes the provided block immediately.

Note that passing an `NSError` object is valid usage and will reject this promise.
*/
+ (PMKPromise *)promiseWithValue:(id)value;


- (BOOL)pending;

/**
 A resolved promise is not pending. It is either fulfilled, or
 rejected.
**/
- (BOOL)resolved;
- (BOOL)fulfilled;
- (BOOL)rejected;

/**
 A promise has a nil value if it is pending. A promise is still
 pending if the `then` or `catch` that created this promise
 returned a `Promise`.
*/
- (id)value;

/**
 Create a new root Promise.

 Pass a block to this constructor, the block must take two arguments that point to the `fulfiller` and `rejecter` of this Promise. Fulfill or reject this Promise using those blocks and the Promise chain that roots to this Promise will be resolved accordingly.

 Should you need to fulfill a promise but have no sensical value to use; fulfill with `nil`.
*/
+ (instancetype)new:(void(^)(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject))block;

@end



/**
 Use with `+new:`, or return from a `then` or `catch` handler to fulfill
 a promise with multiple arguments.

 Consumers of your Promise are not compelled to consume any arguments and
 in fact will often only consume the first parameter. Thus ensure the
 order of parameters is: from most-important to least-important.
 
 Currently PromiseKit limits you to THREE parameters to the manifold.
*/
#define PMKManifold(...) __PMKManifold(__VA_ARGS__, 3, 2, 1)
#define __PMKManifold(_1, _2, _3, N, ...) [PMKArray:N, _1, _2, _3]
@interface PMKArray : NSObject
// returning `id` to avoid compiler issues: https://github.com/mxcl/PromiseKit/issues/76
+ (id):(NSUInteger)count, ...;
@end




/**
Executes @param block via `dispatch_async` with `DISPATCH_QUEUE_PRIORITY_DEFAULT`.

The returned `Promise` is resolved with the value returned from @param block (if any). Any `then` or `catch` attached to the returned `Promise` is exectued on the main queue.

@param block A block to be executed in the background.
@return A new `Promise` to be executed after @param block.
*/
PMKPromise *dispatch_promise(id block);

/**
 Executes @param block via `dispatch_async` on the specified queue.
 @see dispatch_promise
 */
PMKPromise *dispatch_promise_on(dispatch_queue_t q, id block);
