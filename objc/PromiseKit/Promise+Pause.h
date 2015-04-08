#import <PromiseKit/Promise.h>
#import <Foundation/Foundation.h>

@interface PMKPromise (Pause)

/**
 Pauses the chain for the specified number of seconds.

 @parameter duration The duration in seconds to wait before resolving this promise.

 @return A new promise fulfilled with two parameters:
 1. The previous promise’s fulfillment.
 2. The duration the chain was suspended.

 For example:

    [PMKPromise promiseWithValue:@"mxcl"].pause(1.5).then(^(NSString *string, NSNumber *duration){
        // string => @"mxcl"
        // duration => @1.5
    });

 @warning *Caveat* Any promise that was previously resolved with `PMKManifold` will lose
 parameters beyond the first parameter.
*/
- (PMKPromise *(^)(NSTimeInterval duration))pause;

/**
 @param duration The duration in seconds to wait before resolving this promise.
 @return A promise that thens the duration it waited before resolving.
*/
+ (PMKPromise *)pause:(NSTimeInterval)duration;

@end
