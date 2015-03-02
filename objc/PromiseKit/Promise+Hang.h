#import <PromiseKit/Promise.h>

/**
 To import `+hang:`:

    pod "PromiseKit/Hang"
*/
@interface PMKPromise (Hang)

/**
 Literally hangs this thread until the promise has resolved. By all means
 use this for testing and debugging, but please! Don’t leave `hang` in
 production code! It could literally *hang* your app! The implementation
 uses {CF|NS}RunLoop.
*/
+ (id)hang:(PMKPromise *)promise;

@end
