#import "PromiseKit+UIAnimation.h"
#import "PromiseKit+Foundation.h"
#import "PromiseKit/Promise.h"

#define PMKMainThreadError [NSError errorWithDomain:PMKErrorDomain code:PMKInvalidUsageError userInfo:@{NSLocalizedDescriptionKey: @"Animation was attempted on a background thread"}]


@implementation UIView (PMKUIAnimation)

+ (PMKPromise *)animate:(void(^)(void))animations {
    return [self promiseWithDuration:0.3 delay:0 options:0 animations:animations];
}

+ (PMKPromise *)promiseWithDuration:(NSTimeInterval)duration animations:(void(^)(void))animations {
    return [self promiseWithDuration:duration delay:0 options:0 animations:animations];
}

+ (PMKPromise *)promiseWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options animations:(void(^)(void))animations
{
    NSAssert([NSThread isMainThread], @"UIKit animation must be performed on the main thread");

    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter){
        if (![NSThread isMainThread])
            return rejecter(PMKMainThreadError);

        [UIView animateWithDuration:duration delay:delay options:options animations:animations completion:^(BOOL finished) {
            fulfiller(@(finished));
        }];
    }];
}

+ (PMKPromise *)promiseWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay usingSpringWithDamping:(CGFloat)dampingRatio initialSpringVelocity:(CGFloat)velocity options:(UIViewAnimationOptions)options animations:(void(^)(void))animations
{
    NSAssert([NSThread isMainThread], @"UIKit animation must be performed on the main thread");

    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter){
        if (![NSThread isMainThread])
            return rejecter(PMKMainThreadError);

        [UIView animateWithDuration:duration delay:delay usingSpringWithDamping:dampingRatio initialSpringVelocity:velocity options:options animations:animations completion:^(BOOL finished) {
            fulfiller(@(finished));
        }];
    }];
}

+ (PMKPromise *)promiseWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewKeyframeAnimationOptions)options keyframeAnimations:(void(^)(void))animations
{
    NSAssert([NSThread isMainThread], @"UIKit animation must be performed on the main thread");

    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter){
        if (![NSThread isMainThread])
            return rejecter(PMKMainThreadError);

        [UIView animateKeyframesWithDuration:duration delay:delay options:options animations:animations completion:^(BOOL finished) {
            fulfiller(@(finished));
        }];
    }];
}





@end
