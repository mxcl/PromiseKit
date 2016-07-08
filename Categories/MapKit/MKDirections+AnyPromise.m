#import "MKDirections+AnyPromise.h"
@import PromiseKit;


@implementation MKDirections (PromiseKit)

- (AnyPromise *)calculateDirections {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self calculateDirectionsWithCompletionHandler:^(id rsp, id err){
            resolve(err ?: rsp);
        }];
    }];
}

- (AnyPromise *)calculateETA {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self calculateETAWithCompletionHandler:^(id rsp, id err){
            resolve(err ?: rsp);
        }];
    }];
}

@end



@implementation MKDirections (PMKDeprecated)

+ (AnyPromise *)promise:(MKDirectionsRequest *)request {
    return [[[MKDirections alloc] initWithRequest:request] calculateDirections];
}

+ (AnyPromise *)promiseETA:(MKDirectionsRequest *)request {
    return [[[MKDirections alloc] initWithRequest:request] calculateETA];
}

@end
