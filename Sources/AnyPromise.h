#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#import <PromiseKit/fwd.h>

/// INTERNAL DO NOT USE
@class __AnyPromise;

/// Provided to simplify some usage sites
typedef void (^PMKResolver)(id __nullable) NS_REFINED_FOR_SWIFT;


/// An Objective-C implementation of the promise pattern.
@interface AnyPromise: NSObject

/**
 Create a new promise that resolves with the provided block.

 Use this method when wrapping asynchronous code that does *not* use promises so that this code can be used in promise chains.

 If `resolve` is called with an `NSError` object, the promise is rejected, otherwise the promise is fulfilled.

 Don’t use this method if you already have promises! Instead, just return your promise.

 Should you need to fulfill a promise but have no sensical value to use: your promise is a `void` promise: fulfill with `nil`.

 The block you pass is executed immediately on the calling thread.

 - Parameter block: The provided block is immediately executed, inside the block call `resolve` to resolve this promise and cause any attached handlers to execute. If you are wrapping a delegate-based system, we recommend instead to use: initWithResolver:
 - Returns: A new promise.
 - Warning: Resolving a promise with `nil` fulfills it.
 - SeeAlso: https://github.com/mxcl/PromiseKit/blob/master/Documentation/GettingStarted.md#making-promises
 - SeeAlso: https://github.com/mxcl/PromiseKit/blob/master/Documentation/CommonPatterns.md#wrapping-delegate-systems
 */
+ (instancetype __nonnull)promiseWithResolverBlock:(void (^ __nonnull)(__nonnull PMKResolver))resolveBlock NS_REFINED_FOR_SWIFT;


/// INTERNAL DO NOT USE
- (instancetype __nonnull)initWith__D:(__AnyPromise * __nonnull)d;

/**
 Creates a resolved promise.

 When developing your own promise systems, it is occasionally useful to be able to return an already resolved promise.

 - Parameter value: The value with which to resolve this promise. Passing an `NSError` will cause the promise to be rejected, passing an AnyPromise will return a new AnyPromise bound to that promise, otherwise the promise will be fulfilled with the value passed.
 - Returns: A resolved promise.
 */
+ (instancetype __nonnull)promiseWithValue:(__nullable id)value NS_REFINED_FOR_SWIFT;

/**
 The value of the asynchronous task this promise represents.

 A promise has `nil` value if the asynchronous task it represents has not finished. If the value is `nil` the promise is still `pending`.

 - Warning: *Note* Our Swift variant’s value property returns nil if the promise is rejected where AnyPromise will return the error object. This fits with the pattern where AnyPromise is not strictly typed and is more dynamic, but you should be aware of the distinction.

 - Note: If the AnyPromise was fulfilled with a `PMKManifold`, returns only the first fulfillment object.

 - Returns: The value with which this promise was resolved or `nil` if this promise is pending.
 */
@property (nonatomic, readonly) __nullable id value NS_REFINED_FOR_SWIFT;

/// - Returns: if the promise is pending resolution.
@property (nonatomic, readonly) BOOL pending NS_REFINED_FOR_SWIFT;

/// - Returns: if the promise is resolved and fulfilled.
@property (nonatomic, readonly) BOOL fulfilled NS_REFINED_FOR_SWIFT;

/// - Returns: if the promise is resolved and rejected.
@property (nonatomic, readonly) BOOL rejected NS_REFINED_FOR_SWIFT;


/**
 The provided block is executed when its receiver is fulfilled.

 If you provide a block that takes a parameter, the value of the receiver will be passed as that parameter.

    [NSURLSession GET:url].then(^(NSData *data){
        // do something with data
    });

 @return A new promise that is resolved with the value returned from the provided block. For example:

    [NSURLSession GET:url].then(^(NSData *data){
        return data.length;
    }).then(^(NSNumber *number){
        //…
    });

 @warning *Important* The block passed to `then` may take zero, one, two or three arguments, and return an object or return nothing. This flexibility is why the method signature for then is `id`, which means you will not get completion for the block parameter, and must type it yourself. It is safe to type any block syntax here, so to start with try just: `^{}`.

 @warning *Important* If an `NSError` or `NSString` is thrown inside your block, or you return an `NSError` object the next `Promise` will be rejected. See `catch` for documentation on error handling.

 @warning *Important* `then` is always executed on the main queue.

 @see thenOn
 @see thenInBackground
*/
- (AnyPromise * __nonnull (^ __nonnull)(id __nonnull))then NS_REFINED_FOR_SWIFT;


/**
 The provided block is executed on the default queue when the receiver is fulfilled.

 This method is provided as a convenience for `thenOn`.

 @see then
 @see thenOn
*/
- (AnyPromise * __nonnull(^ __nonnull)(id __nonnull))thenInBackground NS_REFINED_FOR_SWIFT;

/**
 The provided block is executed on the dispatch queue of your choice when the receiver is fulfilled.

 @see then
 @see thenInBackground
*/
- (AnyPromise * __nonnull(^ __nonnull)(dispatch_queue_t __nonnull, id __nonnull))thenOn NS_REFINED_FOR_SWIFT;

#ifndef __cplusplus
/**
 The provided block is executed when the receiver is rejected.

 Provide a block of form `^(NSError *){}` or simply `^{}`. The parameter has type `id` to give you the freedom to choose either.

 The provided block always runs on the main queue.

 @warning *Note* Cancellation errors are not caught.

 @warning *Note* Since catch is a c++ keyword, this method is not available in Objective-C++ files. Instead use catchOn.

 @see catchOn
 @see catchInBackground
*/
- (AnyPromise * __nonnull(^ __nonnull)(id __nonnull))catch NS_REFINED_FOR_SWIFT;
#endif

/**
 The provided block is executed when the receiver is rejected.

 Provide a block of form `^(NSError *){}` or simply `^{}`. The parameter has type `id` to give you the freedom to choose either.

 The provided block always runs on the global background queue.

 @warning *Note* Cancellation errors are not caught.

 @warning *Note* Since catch is a c++ keyword, this method is not available in Objective-C++ files. Instead use catchWithPolicy.

 @see catch
 @see catchOn
 */
- (AnyPromise * __nonnull(^ __nonnull)(id __nonnull))catchInBackground NS_REFINED_FOR_SWIFT;


/**
 The provided block is executed when the receiver is rejected.

 Provide a block of form `^(NSError *){}` or simply `^{}`. The parameter has type `id` to give you the freedom to choose either.

 The provided block always runs on queue provided.

 @warning *Note* Cancellation errors are not caught.

 @see catch
 @see catchInBackground
 */
- (AnyPromise * __nonnull(^ __nonnull)(dispatch_queue_t __nonnull, id __nonnull))catchOn NS_REFINED_FOR_SWIFT;

/**
 The provided block is executed when the receiver is resolved.

 The provided block always runs on the main queue.

 @see ensureOn
*/
- (AnyPromise * __nonnull(^ __nonnull)(dispatch_block_t __nonnull))ensure NS_REFINED_FOR_SWIFT;

/**
 The provided block is executed on the dispatch queue of your choice when the receiver is resolved.

 @see ensure
 */
- (AnyPromise * __nonnull(^ __nonnull)(dispatch_queue_t __nonnull, dispatch_block_t __nonnull))ensureOn NS_REFINED_FOR_SWIFT;

/**
 The provided block is executed on the global background queue when the receiver is resolved.

 @see ensure
 */
- (AnyPromise * __nonnull(^ __nonnull)(dispatch_block_t __nonnull))ensureInBackground NS_REFINED_FOR_SWIFT;

/**
 Wait until the promise is resolved.

 @return Value if fulfilled or error if rejected.
 */
- (id __nullable)wait NS_REFINED_FOR_SWIFT;

/**
 Create a new promise with an associated resolver.

 Use this method when wrapping asynchronous code that does *not* use
 promises so that this code can be used in promise chains. Generally,
 prefer `promiseWithResolverBlock:` as the resulting code is more elegant.

     PMKResolver resolve;
     AnyPromise *promise = [[AnyPromise alloc] initWithResolver:&resolve];

     // later
     resolve(@"foo");

 @param resolver A reference to a block pointer of PMKResolver type.
 You can then call your resolver to resolve this promise.

 @return A new promise.

 @warning *Important* The resolver strongly retains the promise.

 @see promiseWithResolverBlock:
*/
- (instancetype __nonnull)initWithResolver:(PMKResolver __strong __nonnull * __nonnull)resolver NS_REFINED_FOR_SWIFT;

/**
 Unavailable methods
 */

- (instancetype __nonnull)init __attribute__((unavailable("It is illegal to create an unresolvable promise.")));
+ (instancetype __nonnull)new __attribute__((unavailable("It is illegal to create an unresolvable promise.")));
- (AnyPromise * __nonnull(^ __nonnull)(dispatch_block_t __nonnull))always __attribute__((unavailable("See -ensure")));
- (AnyPromise * __nonnull(^ __nonnull)(dispatch_block_t __nonnull))alwaysOn __attribute__((unavailable("See -ensureOn")));
- (AnyPromise * __nonnull(^ __nonnull)(dispatch_block_t __nonnull))finally __attribute__((unavailable("See -ensure")));
- (AnyPromise * __nonnull(^ __nonnull)(dispatch_block_t __nonnull, dispatch_block_t __nonnull))finallyOn __attribute__((unavailable("See -ensureOn")));

@end


typedef void (^PMKAdapter)(id __nullable, NSError * __nullable) NS_REFINED_FOR_SWIFT;
typedef void (^PMKIntegerAdapter)(NSInteger, NSError * __nullable) NS_REFINED_FOR_SWIFT;
typedef void (^PMKBooleanAdapter)(BOOL, NSError * __nullable) NS_REFINED_FOR_SWIFT;


@interface AnyPromise (Adapters)

/**
 Create a new promise by adapting an existing asynchronous system.

 The pattern of a completion block that passes two parameters, the first
 the result and the second an `NSError` object is so common that we
 provide this convenience adapter to make wrapping such systems more
 elegant.

    return [PMKPromise promiseWithAdapterBlock:^(PMKAdapter adapter){
        PFQuery *query = [PFQuery …];
        [query findObjectsInBackgroundWithBlock:adapter];
    }];

 @warning *Important* If both parameters are nil, the promise fulfills,
 if both are non-nil the promise rejects. This is per the convention.

 @see https://github.com/mxcl/PromiseKit/blob/master/Documentation/GettingStarted.md#making-promises
 */
+ (instancetype __nonnull)promiseWithAdapterBlock:(void (^ __nonnull)(PMKAdapter __nonnull adapter))block NS_REFINED_FOR_SWIFT;

/**
 Create a new promise by adapting an existing asynchronous system.

 Adapts asynchronous systems that complete with `^(NSInteger, NSError *)`.
 NSInteger will cast to enums provided the enum has been wrapped with
 `NS_ENUM`. All of Apple’s enums are, so if you find one that hasn’t you
 may need to make a pull-request.

 @see promiseWithAdapter
 */
+ (instancetype __nonnull)promiseWithIntegerAdapterBlock:(void (^ __nonnull)(PMKIntegerAdapter __nonnull adapter))block NS_REFINED_FOR_SWIFT;

/**
 Create a new promise by adapting an existing asynchronous system.

 Adapts asynchronous systems that complete with `^(BOOL, NSError *)`.

 @see promiseWithAdapter
 */
+ (instancetype __nonnull)promiseWithBooleanAdapterBlock:(void (^ __nonnull)(PMKBooleanAdapter __nonnull adapter))block NS_REFINED_FOR_SWIFT;

@end


#ifdef __cplusplus
extern "C" {
#endif

/**
 Whenever resolving a promise you may resolve with a tuple, eg.
 returning from a `then` or `catch` handler or resolving a new promise.

 Consumers of your Promise are not compelled to consume any arguments and
 in fact will often only consume the first parameter. Thus ensure the
 order of parameters is: from most-important to least-important.

 Currently PromiseKit limits you to THREE parameters to the manifold.
*/
#define PMKManifold(...) __PMKManifold(__VA_ARGS__, 3, 2, 1)
#define __PMKManifold(_1, _2, _3, N, ...) __PMKArrayWithCount(N, _1, _2, _3)
extern id __nonnull __PMKArrayWithCount(NSUInteger, ...);

#ifdef __cplusplus
}   // Extern C
#endif




__attribute__((unavailable("See AnyPromise")))
@interface PMKPromise
@end
