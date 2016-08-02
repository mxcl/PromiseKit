//
//  CALayer+PromiseKit.h
//
//  Created by María Patricia Montalvo Dzib on 24/11/14.
//  Copyright (c) 2014 Aluxoft SCP. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <PromiseKit/fwd.h>

/**
 To import the `CALayer` category:

    pod "PromiseKit/CALayer"

 Or you can import all categories on `QuartzCore`:

    pod "PromiseKit/QuartzCore"

 Or `CALayer` is one of the categories imported by the umbrella pod:

    pod "PromiseKit"
*/
@interface CALayer (PromiseKit)

/**
 Add the specified animation object to the layer’s render tree.

 @return A promise that thens two parameters:
 1. A boolean: `YES` if the animation progressed entirely to completion.
 2. the `CAAnimation` object.

 @see addAnimation:forKey
*/
-(PMKPromise *)promiseAnimation:(CAAnimation *)animation forKey:(NSString *)key;


@end
