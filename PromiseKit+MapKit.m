#import "PromiseKit/Promise.h"
#import "PromiseKit+MapKit.h"


#if PMK_DEPLOY_7

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



@implementation MKMapSnapshotter (PromiseKit)

- (PMKPromise *)promise {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        [self startWithCompletionHandler:^(MKMapSnapshot *snapshot, NSError *error) {
            if (error)
                rejecter(error);
            else
                fulfiller(snapshot);
        }];
    }];
}

@end

#endif
