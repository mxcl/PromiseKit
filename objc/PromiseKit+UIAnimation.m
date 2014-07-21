#import "PromiseKit+UIAnimation.h"
#import "PromiseKit+Foundation.h"
#import "PromiseKit/Promise.h"

@implementation UIView (PromiseKit_UIAnimation)


+ (PMKPromise *)promiseAnimationWithDuration:(NSTimeInterval)duration
                                  animations:(void (^)(void))animations{
    
    NSAssert([NSThread isMainThread],@"require main thread");
    
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejunker){
        
        [UIView animateWithDuration:duration
                         animations:animations
                         completion:^(BOOL finished) {
                             fulfiller([NSNumber numberWithBool:finished]);
                         }];
        
    }];
}

+ (PMKPromise *)promiseAnimationWithDuration:(NSTimeInterval)duration
                                       delay:(NSTimeInterval)delay
                                     options:(UIViewAnimationOptions)options
                                  animations:(void (^)(void))animations{
    NSAssert([NSThread isMainThread],@"require main thread");
    
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejunker){
        
        [UIView animateWithDuration:duration
                              delay:delay
                            options:options
                         animations:animations
                         completion:^(BOOL finished) {
                             fulfiller([NSNumber numberWithBool:finished]);
                         }];
        
    }];
}

+ (PMKPromise *)promiseAnimateKeyframesWithDuration:(NSTimeInterval)duration
                                              delay:(NSTimeInterval)delay
                                            options:(UIViewKeyframeAnimationOptions)options
                                         animations:(void (^)(void))animations {
    NSAssert([NSThread isMainThread],@"require main thread");
    
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejunker){
        
        [UIView animateKeyframesWithDuration:duration delay:delay options:options animations:animations completion:^(BOOL finished) {
                        fulfiller([NSNumber numberWithBool:finished]);
        }];
    }];
}

+ (PMKPromise *)promiseAnimateWithDuration:(NSTimeInterval)duration
                                     delay:(NSTimeInterval)delay
                    usingSpringWithDamping:(CGFloat)dampingRatio
                     initialSpringVelocity:(CGFloat)velocity
                                   options:(UIViewAnimationOptions)options
                                animations:(void (^)(void))animations{
    NSAssert([NSThread isMainThread],@"require main thread");
    
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejunker){
        
        [UIView animateWithDuration:duration
                              delay:delay
             usingSpringWithDamping:dampingRatio
              initialSpringVelocity:velocity
                            options:options
                         animations:animations
                         completion:^(BOOL finished) {
                             fulfiller([NSNumber numberWithBool:finished]);
        }];
    }];
}


@end
