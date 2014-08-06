#import "MKMapSnapshotter+PromiseKit.h"
#import "PromiseKit/Promise.h"

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
