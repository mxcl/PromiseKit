#import <UIKit/UIKit.h>

@class PMKPromise;

@interface UIView (PromiseKit_UIAnimation)
+ (PMKPromise *)promiseAnimationWithDuration:(NSTimeInterval)duration
                                  animations:(void (^)(void))animations;

+ (PMKPromise *)promiseAnimationWithDuration:(NSTimeInterval)duration
                                       delay:(NSTimeInterval)delay
                                     options:(UIViewAnimationOptions)options
                                  animations:(void (^)(void))animations;

+ (PMKPromise *)promiseAnimateKeyframesWithDuration:(NSTimeInterval)duration
                                              delay:(NSTimeInterval)delay
                                            options:(UIViewKeyframeAnimationOptions)options
                                         animations:(void (^)(void))animations  NS_AVAILABLE_IOS(7_0);

+ (PMKPromise *)promiseAnimateWithDuration:(NSTimeInterval)duration
                                     delay:(NSTimeInterval)delay
                    usingSpringWithDamping:(CGFloat)dampingRatio
                     initialSpringVelocity:(CGFloat)velocity
                                   options:(UIViewAnimationOptions)options
                                animations:(void (^)(void))animations  NS_AVAILABLE_IOS(7_0);
@end
