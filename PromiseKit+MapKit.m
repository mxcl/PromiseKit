#import "PromiseKit/Promise.h"
#import "PromiseKit+MapKit.h"


@implementation MKDirections (PromiseKit)

+ (Promise *)promise:(MKDirectionsRequest *)request {
    return [Promise new:^(PromiseResolver fulfiller, PromiseResolver rejecter) {
        [[[MKDirections alloc] initWithRequest:request] calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
            if (error) {
                rejecter(error);
            } else
                fulfiller(response);
        }];
    }];
}

+ (Promise *)promiseETA:(MKDirectionsRequest *)request {
    return [Promise new:^(PromiseResolver fulfiller, PromiseResolver rejecter) {
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

- (Promise *)promise {
    return [Promise new:^(PromiseResolver fulfiller, PromiseResolver rejecter) {
        [self startWithCompletionHandler:^(MKMapSnapshot *snapshot, NSError *error) {
            if (error)
                rejecter(error);
            else
                fulfiller(snapshot);
        }];
    }];
}

@end