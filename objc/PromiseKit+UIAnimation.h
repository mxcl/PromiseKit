//
//  UIView+PromiseKit_UIAnimation.h
//  YahooDenaStudy
//
//  Created by Masafumi Yoshida on 2014/07/11.
//  Copyright (c) 2014年 DeNA. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PMKPromise;

@interface UIView (PMKUIAnimation)


/**
 Returns a new promise that fulfills when the properties changed in the
 provided block have completed animation over 0.3 seconds.

 “Then”s the `BOOL` that the underlying `completion` block receives.
*/
+ (PMKPromise *)animate:(void(^)(void))animations;

/**
 Returns a new promise that fulfills when the properties changed in the
 provided block have completed animation over `duration` seconds.

 “Then”s the `BOOL` that the underlying `completion` block receives.
*/
+ (PMKPromise *)promiseWithDuration:(NSTimeInterval)duration animations:(void(^)(void))animations;

/**
 Returns a new promise that fulfills when the properties changed in the
 provided block have completed animation over `duration` seconds with
 initial `delay` and the provided animation `options`.

 “Then”s the `BOOL` that the underlying `completion` block receives.
*/
+ (PMKPromise *)promiseWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options animations:(void(^)(void))animations;

/**
 Returns a new promise that fulfills when the properties changed in the
 provided block have completed animation over `duration` seconds with
 initial `delay`, the provided animation `options` and the provided
 spring physics constants applied.

 “Then”s the `BOOL` that the underlying `completion` block receives.
*/
+ (PMKPromise *)promiseWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay usingSpringWithDamping:(CGFloat)dampingRatio initialSpringVelocity:(CGFloat)velocity options:(UIViewAnimationOptions)options animations:(void(^)(void))animations;

/**
 0.2.4.6.8.0.2.4.6.8.0.2.4.6.8.0.2.4.6.8.0.2.4.6.8.0.2.4.6.8.0.2.4.6.8.
 Returns a new promise that fulfills when the properties changed in the
 provided block have completed keyframe animation over `duration`
 seconds with initial `delay` and the provided keyframe animation
 `options` applied.

 “Then”s the `BOOL` that the underlying `completion` block receives.
*/
+ (PMKPromise *)promiseWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewKeyframeAnimationOptions)options keyframeAnimations:(void(^)(void))animations;




+ (PMKPromise *)promiseAnimationWithDuration:(NSTimeInterval)duration
                                  animations:(void (^)(void))animations
                __attribute__((deprecated("Use -promiseWithDuration:animations:")));

+ (PMKPromise *)promiseAnimationWithDuration:(NSTimeInterval)duration
                                       delay:(NSTimeInterval)delay
                                     options:(UIViewAnimationOptions)options
                                  animations:(void (^)(void))animations
                __attribute__((deprecated("Use -promiseithDuration:delay:options:animations:")));

+ (PMKPromise *)promiseAnimateKeyframesWithDuration:(NSTimeInterval)duration
                                              delay:(NSTimeInterval)delay
                                            options:(UIViewKeyframeAnimationOptions)options
                                         animations:(void (^)(void))animations
                __attribute__((deprecated("Use -promiseWithDuration:delay:options:keyframeAnimations:")));

+ (PMKPromise *)promiseAnimateWithDuration:(NSTimeInterval)duration
                                     delay:(NSTimeInterval)delay
                    usingSpringWithDamping:(CGFloat)dampingRatio
                     initialSpringVelocity:(CGFloat)velocity
                                   options:(UIViewAnimationOptions)options
                                animations:(void (^)(void))animations
                __attribute__((deprecated("Use -promiseWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:")));
@end
