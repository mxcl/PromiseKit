#import <dispatch/dispatch.h>
#import <Foundation/NSError.h>
#import <Foundation/NSArray.h>
#import <PromiseKit/fwd.h>

/**
 A promise represents the future value of a task.

 To obtain the value of a promise we call `then`.

 Promises are chainable: `then` returns a promise, you can call `then` on that promise, which  returns a promise, you can call `then` on that promise, et cetera.

 Promises start in a pending state: they have `nil` value. Promises *resolve* to become *fulfilled* or *rejected*. A rejected promise has an `NSError` for its value, a fulfilled promise has any other object as its value.

 @see [PromiseKit `then` Guide](http://promisekit.org/then/)
 @see [PromiseKit Chaining Guide](http://promisekit.org/chaining/)
*/
@interface PMKPromise : NSObject

/**
 The provided block is executed when its receiver is resolved.

 If you provide a block that takes a parameter, the value of the receiver will be passed as that parameter.

 @param block The block that is executed when the receiver is resolved.

    [NSURLConnection GET:url].then(^(NSData *data){
        // do something with data
    });

 @return A new promise that is resolved with the value returned from the provided block. For example:

    [NSURLConnection GET:url].then(^(NSData *data){
        return data.length;
    }).then(^(NSNumber *number){
        //…
    });

 @warning *Important* The block passed to `then` may take zero, one, two or three arguments, and return an object or return nothing. This flexibility is why the method signature for then is `id`, which means you will not get completion for the block parameter, and must type it yourself. It is safe to type any block syntax here, so to start with try just: `^{}`.

 @warning *Important* If an exception is thrown inside your block, or you return an `NSError` object the next `Promise` will be rejected. See `catch` for documentation on error handling.

 @warning *Important* `then` is always executed on the main queue.

 @see thenOn
 @see thenInBackground
*/
- (PMKPromise *(^)(id))then;

/**
 The provided block is executed on the default queue when the receiver is fulfilled.

 This method is provided as a convenience for `thenOn`.

 @see then
 @see thenOn
 */
- (PMKPromise *(^)(id))thenInBackground;

#if !__cplusplus
/**
 The provided block is executed when the receiver is rejected.

 Provide a block of form `^(NSError *){}` or simply `^{}`. The parameter has type `id` to give you the freedom to choose either.

 The provided block always runs on the main queue.
 
 Note, since catch is a c++ keyword, this method is not availble in Objective-C++ files. Instead use catchOn.

 @see catchOn
*/
- (PMKPromise *(^)(id))catch;  // catch is a c++ keyword
#endif

/**
 The provided block is executed when the receiver is resolved.

 The provided block always runs on the main queue.

 @see catchOn
*/
- (PMKPromise *(^)(void(^)(void)))finally;

/**
 The provided block is executed on the dispatch queue of your choice when the receiver is fulfilled.

 @see then
 @see thenInBackground
*/
- (PMKPromise *(^)(dispatch_queue_t, id))thenOn;

/**
 The provided block is executed on the dispatch queue of your choice when the receiver is rejected.

 @see catch
*/
- (PMKPromise *(^)(dispatch_queue_t, id))catchOn;

/**
 The provided block is executed on the dispatch queue of your choice when the receiver is resolved.

 @see finally
*/
- (PMKPromise *(^)(dispatch_queue_t, void(^)(void)))finallyOn;

/**
 Creates a resolved promise.

 When developing your own promise systems, it is ocassionally useful to be able to return an already resolved promise.

 @param value The value with which to resolve this promise. Passing an `NSError` will cause the promise to be rejected, otherwise the promise will be fulfilled.

 @return A resolved promise.
*/
+ (PMKPromise *)promiseWithValue:(id)value;


/// @return `YES` if the promise has not yet resolved.
- (BOOL)pending;

/// @return `YES` if the promise has resolved (ie. is fulfilled or rejected) `NO` if it is pending.
- (BOOL)resolved;

/// @return `YES` if the promise is fulfilled, `NO` if it is rejected or pending.
- (BOOL)fulfilled;

/// @return `YES` if the promise is rejected, `NO` if it is fulfilled or pending.
- (BOOL)rejected;

/**
 The value of the asynchronous task this promise represents.

 A promise has `nil` value if the asynchronous task it represents has not
 finished. If the value is `nil` the promise is still `pending`.

 @returns If `resolved` the object that was used to resolve this promise,
 if `pending` nil.
*/
- (id)value;

/**
 Create a new promise that is fulfilled or rejected with the provided
 blocks.

 Use this method when wrapping asynchronous code that does *not* use
 promises so that this code can be used in promise chains.

 Don’t use this method if you already have promises! Instead, just
 return your promise.

 @param block The provided block is immediately executed, any exceptions that occur will be caught and cause the returned promise to be rejected.
   - @param fulfill fulfills the returned promise with the provided value
   - @param reject rejects the returned promise with the provided `NSError`

 Should you need to fulfill a promise but have no sensical value to use;
 your promise is a `void` promise: fulfill with `nil`.

 The block you pass is executed immediately on the calling thread.

 @return A new promise.

 @see http://promisekit.org/sealing-your-own-promises/
 @see http://promisekit.org/wrapping-delegation/
*/
+ (instancetype)new:(void(^)(PMKFulfiller fulfill, PMKRejecter reject))block;

/**
 Create a new promise that is resolved with the provided block.

 Use this method when wrapping asynchronous code that does *not* use
 promises so that this code can be used in promise chains.

 Javascript promise libraries are the basis of most modern implementations
 hence the signature of `+new:`. Such libraries allow anything to fulfill
 or reject promises. Since in PromiseKit we only allow promises to be
 rejected by `NSError` objects, we can determine the promise state with
 one rather than two blocks.

 Pass an `NSError` object to reject the promise, and anything else to
 fulfill it.

    return [PMKPromise promiseWithResolver:^(PMKResolver resolve){
		PFQuery *query = [PFQuery …];
		[query findObjectsInBackgroundWithBlock:^(id objs, id error){
            resolve(objs ?: error);
        }];
	}];

 @warning *Important* Resolving a promise with `nil` fulfills it.

 @see http://promisekit.org/sealing-your-own-promises/
*/
+ (instancetype)promiseWithResolver:(void (^)(PMKResolver resolve))block;

/**
 Create a new promise by adapting an existing asynchronous system.

 The pattern of a completion block that passes two parameters, the first
 the result and the second an `NSError` object is so common that we
 provide this convenience adapter to make wrapping such systems more
 elegant.

    return [PMKPromise promiseWithAdapter:^(PMKAdapter adapter){
        PFQuery *query = [PFQuery …];
        [query findObjectsInBackgroundWithBlock:adapter];
    }];

 @warning *Important* If both parameters are nil, the promise fulfills,
 if both are non-nil the promise rejects. This is per the convention.

 @see http://promisekit.org/sealing-your-own-promises/
*/
+ (instancetype)promiseWithAdapter:(void (^)(PMKAdapter adapter))block;

/**
 Create a new promise by adapting an existing asynchronous system.

 Adapts asynchronous systems that complete with `^(NSInteger, NSError *)`.
 NSInteger will cast to enums provided the enum has been wrapped with
 `NS_ENUM`. All of Apple’s enums are, so if you find one that hasn’t you
 may need to make a pull-request.

 @see promiseWithAdapter
*/
+ (instancetype)promiseWithIntegerAdapter:(void (^)(PMKIntegerAdapter adapter))block;

/**
 Create a new promise by adapting an existing asynchronous system.

 Adapts asynchronous systems that complete with `^(BOOL, NSError *)`.

 @see promiseWithAdapter
*/
+ (instancetype)promiseWithBooleanAdapter:(void (^)(PMKBooleanAdapter adapter))block;


/**
 This function is provided so Swift can use AnyPromise.
 
 It is presented as a typical JS-style “thennable”, you can pass `nil`
 to either parameter and that parameter will be ignored.
*/
- (instancetype)then:(id (^)(id))onFulfilled :(id (^)(id))onRejected;

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
#define __PMKManifold(_1, _2, _3, N, ...) __PMKArrayWithCount(N, _1, _2, _3)
extern id __PMKArrayWithCount(NSUInteger, ...);



/**
 Executes the provided block on a background queue.

 dispatch_promise is a convenient way to start a promise chain where the
 first step needs to run synchronously on a background queue.

 @param block The block to be executed in the background. Returning an `NSError` will reject the promise, everything else (including void) fulfills the promise.

 @return A promise resolved with the provided block.

 @see dispatch_async
*/
PMKPromise *dispatch_promise(id block);

/**
 Executes the provided block on the specified queue.

 @see dispatch_promise
 @see dispatch_async
*/
PMKPromise *dispatch_promise_on(dispatch_queue_t q, id block);



/**
 Called by PromiseKit in the event of unhandled errors.
 The default handler NSLogs the error. Note, your handler is executed
 from an undefined queue, unless you manage thread-safe data, dispatch to
 a safe queue before doing anything else in your handler.
*/
extern void (^PMKUnhandledErrorHandler)(NSError *);
