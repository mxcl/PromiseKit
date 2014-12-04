//
//  CALayer+PromiseKit.h
//
//  Created by María Patricia Montalvo Dzib on 24/11/14.
//  Copyright (c) 2014 Aluxoft SCP. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <PromiseKit/fwd.h>

@interface CALayer (PromiseKit)


-(PMKPromise*) promiseAnimation:(CAAnimation*) animation forKey:(NSString*) key;


@end
