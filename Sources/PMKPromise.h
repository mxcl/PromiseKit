/**
 This header provides some compatibility for PromiseKit 1.x’s
 PMKPromise class. It will eventually be deprecated.
*/

#import <PromiseKit/AnyPromise.h>

typedef void (^PMKFulfiller)(id);
typedef void (^PMKRejecter)(NSError *);

typedef PMKFulfiller PMKPromiseFulfiller;
typedef PMKRejecter PMKPromiseRejecter;

#define PMKUnderlyingExceptionKey NSUnderlyingErrorKey



@interface PMKPromise (BackCompat)

/**
 Create a new promise that is fulfilled or rejected with the provided
 blocks.

 Use this method when wrapping asynchronous code that does *not* use
 promises so that this code can be used in promise chains.

 Don’t use this method if you already have promises! Instead, just
 return your promise.

 Should you need to fulfill a promise but have no sensical value to use;
 your promise is a `void` promise: fulfill with `nil`.

 The block you pass is executed immediately on the calling thread.

 @param block The provided block is immediately executed, any exceptions that occur will be caught and cause the returned promise to be rejected.

  - @param fulfill fulfills the returned promise with the provided value
  - @param reject rejects the returned promise with the provided `NSError`

 @return A new promise.

 @see http://promisekit.org/sealing-your-own-promises/
 @see http://promisekit.org/wrapping-delegation/
*/
+ (instancetype)new:(void(^)(PMKFulfiller fulfill, PMKRejecter reject))block __attribute__((deprecated("Use +promiseWithResolverBlock:")));

/**
 Loops until one or more promises have resolved.

 Because Promises are single-shot, the block to until must return one or more promises. They are then `when`’d. If they succeed the until loop is concluded. If they fail then the @param `catch` handler is executed.

 If the `catch` throws or returns an `NSError` then the loop is ended.

 If the `catch` handler returns a Promise then re-execution of the loop is suspended upon resolution of that Promise. If the Promise succeeds then the loop continues. If it fails the loop ends.

 An example usage is an app starting up that must get data from the Internet before the main ViewController can be shown. You can `until` the poll Promise and in the catch handler decide if the poll should be reattempted or not, perhaps returning a `UIAlertView.promise` allowing the user to choose if they continue or not.
*/
+ (PMKPromise *)until:(id (^)(void))blockReturningPromises catch:(id)failHandler;

@end



#import <Foundation/NSDate.h>

@interface PMKPromise (Deprecated)

+ (PMKPromise *)when:(id)input __attribute__((deprecated("Use PMKWhen()")));
+ (PMKPromise *)pause:(NSTimeInterval)duration __attribute__((deprecated("Use PMKAfter()")));
+ (PMKPromise *)join:(id)input __attribute__((deprecated("Use PMKJoin()")));

- (PMKPromise *( ^ ) ( id ))thenUnleashZalgo __attribute__((unavailable("If you need this, open a ticket, we will provide it, I just want to say hi.")));

+ (PMKPromise *)promiseWithResolver:(PMKResolver)block __attribute__((deprecated("Use +promiseWithResolverBlock:")));
+ (instancetype)promiseWithAdapter:(void (^)(PMKAdapter adapter))block __attribute__((deprecated("Use +promiseWithAdapterBlock:")));
+ (instancetype)promiseWithIntegerAdapter:(void (^)(PMKIntegerAdapter adapter))block __attribute__((deprecated("Use +promiseWithIntegerAdapterBlock:")));
+ (instancetype)promiseWithBooleanAdapter:(void (^)(PMKBooleanAdapter adapter))block __attribute__((deprecated("Use +promiseWithBooleanAdapterBlock:")));

@end



extern void (^PMKUnhandledErrorHandler)(NSError *) __attribute__((unavailable("Use PMKSetUnhandledErrorHandler()")));
