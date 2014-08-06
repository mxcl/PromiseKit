#import "MKDirections+PromiseKit.h"
#import "PromiseKit/Promise.h"


@implementation MKDirections (PromiseKit)

+ (PMKPromise *)promise:(MKDirectionsRequest *)request {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        [[[MKDirections alloc] initWithRequest:request] calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
            if (error) {
                rejecter(error);
            } else
                fulfiller(response);
        }];
    }];
}

+ (PMKPromise *)promiseETA:(MKDirectionsRequest *)request {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        [[[MKDirections alloc] initWithRequest:request] calculateETAWithCompletionHandler:^(MKETAResponse *response, NSError *error) {
            if (error) {
                rejecter(error);
            } else
                fulfiller(response);
        }];
    }];
}

@end
