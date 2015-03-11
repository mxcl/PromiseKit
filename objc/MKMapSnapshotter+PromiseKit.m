#import "MKMapSnapshotter+PromiseKit.h"
#import "PromiseKit/Promise.h"

@implementation MKMapSnapshotter (PromiseKit)

- (PMKPromise *)promise {
    return [PMKPromise promiseWithAdapter:^(PMKAdapter adapter) {
        [self startWithCompletionHandler:adapter];
    }];
}

@end
