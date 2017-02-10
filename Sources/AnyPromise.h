#import <Foundation/Foundation.h>
#import <PromiseKit/PromiseKit.h>

// exists to ease porting from PMK 4.x

typedef void (^PMKResolver)(id __nullable) NS_REFINED_FOR_SWIFT;


#if __has_include("PromiseKit-Swift.h")

    // we define this because PromiseKit-Swift.h imports
    // PromiseKit.h which then expects this header already
    // to have been fully imported… !
    @class AnyPromise;

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored"-Wdocumentation"
    #import "PromiseKit-Swift.h"
    #pragma clang diagnostic pop
#else
    // this hack because `AnyPromise` is Swift, but we add
    // our own methods via the below category. This hack is
    // only required while building PromiseKit since, once
    // built, the generated -Swift header exists.

    __attribute__((objc_subclassing_restricted)) __attribute__((objc_runtime_name("AnyPromise")))
    @interface AnyPromise : NSObject
    + (instancetype __nonnull)promiseWithResolverBlock:(void (^ __nonnull)(__nonnull PMKResolver))resolveBlock;
    @end
#endif



@interface AnyPromise (ObjC)

/**
 The provided block is executed when its receiver is resolved.

 If you provide a block that takes a parameter, the value of the receiver will be passed as that parameter.

    [NSURLSession GET:url].then(^(NSData *data){
        // do something with data
    });

 @return A new promise that is resolved with the value returned from the provided block. For example:

    [[NSURLSession shared] dataTaskWithURL:url].then(^(NSData *data){
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
 The provided block is executed on the dispatch queue of your choice when the receiver is fulfilled.

 @see then
 @see thenInBackground
*/
- (AnyPromise * __nonnull(^ __nonnull)(dispatch_queue_t __nonnull, id __nonnull))thenOn NS_REFINED_FOR_SWIFT;

/**
 The provided block is executed on the default queue when the receiver is fulfilled.

 This method is provided as a convenience for `thenOn`.

 @see then
 @see thenOn
*/
- (AnyPromise * __nonnull(^ __nonnull)(id __nonnull))thenInBackground NS_REFINED_FOR_SWIFT;

#ifndef __cplusplus
/**
 The provided block is executed when the receiver is rejected.

 Provide a block of form `^(NSError *){}` or simply `^{}`. The parameter has type `id` to give you the freedom to choose either.

 The provided block always runs on the main queue.
 
 @warning *Note* Cancellation errors are not caught.
 
 @warning *Note* Since catch is a c++ keyword, this method is not availble in Objective-C++ files. Instead use catchWithPolicy.

 @see catchWithPolicy
*/
- (AnyPromise * __nonnull(^ __nonnull)(id __nonnull))catch NS_REFINED_FOR_SWIFT;
#endif

/**
 The provided block is executed when the receiver is resolved.

 The provided block always runs on the main queue.

 @see alwaysOn
*/
- (AnyPromise * __nonnull(^ __nonnull)(dispatch_block_t __nonnull))ensure NS_REFINED_FOR_SWIFT;

/**
 The provided block is executed on the dispatch queue of your choice when the receiver is resolved.

 @see always
 */
- (AnyPromise * __nonnull(^ __nonnull)(dispatch_queue_t __nonnull, dispatch_block_t __nonnull))ensureOn NS_REFINED_FOR_SWIFT;


/// @see ensure
- (AnyPromise * __nonnull(^ __nonnull)(dispatch_block_t __nonnull))finally __attribute__((unavailable("Use ensure")));
/// @see ensureOn
- (AnyPromise * __nonnull(^ __nonnull)(dispatch_block_t __nonnull, dispatch_block_t __nonnull))finallyOn __attribute__((unavailable("Use ensureOn")));
/// @see ensure
- (AnyPromise * __nonnull(^ __nonnull)(dispatch_block_t __nonnull))always __attribute__((unavailable("Use ensure")));
/// @see ensureOn
- (AnyPromise * __nonnull(^ __nonnull)(dispatch_block_t __nonnull, dispatch_block_t __nonnull))alwaysOn __attribute__((unavailable("Use ensureOn")));

@end



#define PMKJSONDeserializationOptions ((NSJSONReadingOptions)(NSJSONReadingAllowFragments | NSJSONReadingMutableContainers))



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



extern NSString * __nonnull const PMKErrorDomain;

#define PMKUnexpectedError 1l
#define PMKInvalidUsageError 3l
#define PMKAccessDeniedError 4l
#define PMKOperationCancelled 5l
#define PMKOperationFailed 8l
#define PMKTaskError 9l
#define PMKJoinError 10l



/**
 Really we shouldn’t assume JSON for (application|text)/(x-)javascript,
 really we should return a String of Javascript. However in practice
 for the apps we write it *will be* JSON. Thus if you actually want
 a Javascript String, use the promise variant of our category functions.
*/
#define PMKHTTPURLResponseIsJSON(rsp) [@[@"application/json", @"text/json", @"text/javascript", @"application/x-javascript", @"application/javascript"] containsObject:[rsp MIMEType]]
#define PMKHTTPURLResponseIsImage(rsp) [@[@"image/tiff", @"image/jpeg", @"image/gif", @"image/png", @"image/ico", @"image/x-icon", @"image/bmp", @"image/x-bmp", @"image/x-xbitmap", @"image/x-win-bitmap"] containsObject:[rsp MIMEType]]
#define PMKHTTPURLResponseIsText(rsp) [[rsp MIMEType] hasPrefix:@"text/"]



#if __cplusplus
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

#if __cplusplus
}
#endif


