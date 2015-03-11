//
//  CALayer+PromiseKit.m
//
//  Created by María Patricia Montalvo Dzib on 24/11/14.
//  Copyright (c) 2014 Aluxoft SCP. All rights reserved.
//

#import <objc/runtime.h>
#import <PromiseKit/Promise.h>
#import <QuartzCore/CAAnimation.h>
#import "CALayer+PromiseKit.h"


@interface PMKCAAnimationDelegate : NSObject {
    @public
    void (^fullfiller)(id);
}
@end
@implementation PMKCAAnimationDelegate

-(void) animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    fullfiller(PMKManifold(@(flag), anim));
    PMKRelease(self);
}

@end


@implementation CALayer (PromiseKit)

-(PMKPromise*) promiseAnimation:(CAAnimation*) animation forKey:(NSString*) key {
    PMKCAAnimationDelegate* d = [[PMKCAAnimationDelegate alloc] init];
    PMKRetain(d);
    animation.delegate = d;
    [self addAnimation:animation forKey:key];
    return [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        d->fullfiller = fulfill;
    }];
}

@end
