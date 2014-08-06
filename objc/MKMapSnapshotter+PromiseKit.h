#import <MapKit/MKMapSnapshotter.h>
#import "PromiseKit/fwd.h"

@interface MKMapSnapshotter (PromiseKit)
- (PMKPromise *)promise;
@end
