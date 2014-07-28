#import "PromiseKit/fwd.h"
#import <UIKit/UIViewController.h>
#import <UIKit/UIAlertView.h>
#import <UIKit/UIActionSheet.h>
#import <UIKit/UIView.h>



@interface UIViewController (PromiseKit)

/**
 .2.4.6.8.0.2.4.6.8.0.2.4.6.8.0.2.4.6.8.0.2.4.6.8.0.2.4.6.8.0.2.4.6.8.0.2
 Calls `presentViewController:` such that the presentedViewController can
 call `reject:` or `fulfill:` and resolve the promise. When resolved the
 presentedViewController is dismissed.

 This method is smart and SDK provided ViewControllers like
 `MFMailComposeViewController` will be automatically delegate into the
 returned Promise.
 */
- (PMKPromise *)promiseViewController:(UIViewController *)vc animated:(BOOL)animated completion:(void(^)(void))block;
- (PMKPromise *)promiseSegueWithIdentifier:(NSString*) identifier sender:(id) sender;

- (void)fulfill:(id)result;
- (void)reject:(NSError *)error;

@end



@interface UIAlertView (PromiseKit)
/**
 Thens the dismissedButtonIndex and the alertView itself as the second
 parameter. This promise can not be rejected.
 */
- (PMKPromise *)promise;
@end



@interface UIActionSheet (PromiseKit)
/**
 Thens the dismissedButtonIndex and the actionSheet itself as the second
 parameter. This promise can not be rejected.
 */
- (PMKPromise *)promiseInView:(UIView *)view;
@end



#ifdef PMK_UIANIMATION

//  Created by Masafumi Yoshida on 2014/07/11.
//  Copyright (c) 2014年 DeNA. All rights reserved.

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

#endif
