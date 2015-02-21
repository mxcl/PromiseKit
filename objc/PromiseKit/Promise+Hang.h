#import <PromiseKit/Promise.h>


@interface PMKPromise (Hang)

/**
 0.2.4.6.8.0.2.4.6.8.0.2.4.6.8.0.2.4.6.8.0.2.4.6.8.0.2.4.6.8.0.2.4.6.8.0.2
 Literally hangs this thread until the promise has resolved. By all means
 use this for testing and debugging, but please! Don’t leave it in
 production code! It could literally *hang* your app! The implementation
 uses {CF|NS}RunLoop.
*/
+ (id)hang:(PMKPromise *)promise;
@end
