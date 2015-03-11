#import "MKDirections+PromiseKit.h"
#import "PromiseKit/Promise.h"


@implementation MKDirections (PromiseKit)

+ (PMKPromise *)promise:(MKDirectionsRequest *)request {
    return [PMKPromise promiseWithAdapter:^(PMKAdapter adapter) {
        [[[MKDirections alloc] initWithRequest:request] calculateDirectionsWithCompletionHandler:adapter];
    }];
}

+ (PMKPromise *)promiseETA:(MKDirectionsRequest *)request {
    return [PMKPromise promiseWithAdapter:^(PMKAdapter adapter) {
        [[[MKDirections alloc] initWithRequest:request] calculateETAWithCompletionHandler:adapter];
    }];
}

@end
