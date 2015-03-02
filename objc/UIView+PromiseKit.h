#import <PromiseKit/fwd.h>
#import <UIKit/UIView.h>

//  Created by Masafumi Yoshida on 2014/07/11.
//  Copyright (c) 2014年 DeNA. All rights reserved.

/**
 To import the `UIView` category:

    pod "PromiseKit/UIView"

 Or you can import all categories on `UIKit`:

    pod "PromiseKit/UIKit"

 Or `UIKit` is one of the categories imported by the umbrella pod:

    pod "PromiseKit"
*/
@interface UIView (PromiseKit)

/**
 Returns a new promise that fulfills when the properties changed in the
 provided block have completed animation over 0.3 seconds.

 “Then”s the `BOOL` that the underlying `completion` block receives.
*/
+ (PMKPromise *)animate:(void(^)(void))animations NS_AVAILABLE_IOS(4_0);

/**
 Returns a new promise that fulfills when the properties changed in the
 provided block have completed animation over `duration` seconds.

 “Then”s the `BOOL` that the underlying `completion` block receives.
*/
+ (PMKPromise *)promiseWithDuration:(NSTimeInterval)duration animations:(void(^)(void))animations NS_AVAILABLE_IOS(4_0);

/**
 Returns a new promise that fulfills when the properties changed in the
 provided block have completed animation over `duration` seconds with
 initial `delay` and the provided animation `options`.

 “Then”s the `BOOL` that the underlying `completion` block receives.
*/
+ (PMKPromise *)promiseWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options animations:(void(^)(void))animations NS_AVAILABLE_IOS(4_0);

/**
 Returns a new promise that fulfills when the properties changed in the
 provided block have completed animation over `duration` seconds with
 initial `delay`, the provided animation `options` and the provided
 spring physics constants applied.

 “Then”s the `BOOL` that the underlying `completion` block receives.
*/
+ (PMKPromise *)promiseWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay usingSpringWithDamping:(CGFloat)dampingRatio initialSpringVelocity:(CGFloat)velocity options:(UIViewAnimationOptions)options animations:(void(^)(void))animations NS_AVAILABLE_IOS(7_0);

/**
 Returns a new promise that fulfills when the properties changed in the
 provided block have completed keyframe animation over `duration`
 seconds with initial `delay` and the provided keyframe animation
 `options` applied.

 “Then”s the `BOOL` that the underlying `completion` block receives.
*/
+ (PMKPromise *)promiseWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewKeyframeAnimationOptions)options keyframeAnimations:(void(^)(void))animations NS_AVAILABLE_IOS(7_0);




+ (PMKPromise *)promiseAnimationWithDuration:(NSTimeInterval)duration
                                  animations:(void (^)(void))animations
                PMK_DEPRECATED("Use -promiseWithDuration:animations:");

+ (PMKPromise *)promiseAnimationWithDuration:(NSTimeInterval)duration
                                       delay:(NSTimeInterval)delay
                                     options:(UIViewAnimationOptions)options
                                  animations:(void (^)(void))animations
                PMK_DEPRECATED("Use -promiseithDuration:delay:options:animations:");

+ (PMKPromise *)promiseAnimateKeyframesWithDuration:(NSTimeInterval)duration
                                              delay:(NSTimeInterval)delay
                                            options:(UIViewKeyframeAnimationOptions)options
                                         animations:(void (^)(void))animations
                PMK_DEPRECATED("Use -promiseWithDuration:delay:options:keyframeAnimations:") NS_AVAILABLE_IOS(7_0);

+ (PMKPromise *)promiseAnimateWithDuration:(NSTimeInterval)duration
                                     delay:(NSTimeInterval)delay
                    usingSpringWithDamping:(CGFloat)dampingRatio
                     initialSpringVelocity:(CGFloat)velocity
                                   options:(UIViewAnimationOptions)options
                                animations:(void (^)(void))animations
                PMK_DEPRECATED("Use -promiseWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:") NS_AVAILABLE_IOS(7_0);
@end
