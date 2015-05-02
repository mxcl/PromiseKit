//
//  CALayer+PromiseKit.m
//
//  Created by María Patricia Montalvo Dzib on 24/11/14.
//  Copyright (c) 2014 Aluxoft SCP. All rights reserved.
//

#import <QuartzCore/CAAnimation.h>
#import "CALayer+AnyPromise.h"


@interface PMKCAAnimationDelegate : NSObject {
@public
    PMKResolver resolve;
    id retainCycle;
}
@end

@implementation PMKCAAnimationDelegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    resolve(PMKManifold(@(flag), anim));
    retainCycle = nil;
}

@end



@implementation CALayer (PromiseKit)

- (AnyPromise *)promiseAnimation:(CAAnimation *)animation forKey:(NSString *)key {
    PMKCAAnimationDelegate *d = [PMKCAAnimationDelegate new];
    d->retainCycle = animation.delegate = d;
    [self addAnimation:animation forKey:key];
    return [AnyPromise promiseWithResolver:&d->resolve];
}

@end
