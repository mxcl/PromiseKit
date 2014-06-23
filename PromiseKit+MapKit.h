#import "PromiseKit/fwd.h"


#if PMK_iOS6_ISH

@import MapKit.MKDirections;

@interface MKDirections (PromiseKit)
+ (PMKPromise *)promise:(MKDirectionsRequest *)request;
+ (PMKPromise *)promiseETA:(MKDirectionsRequest *)request;
@end

#endif


#if PMK_iOS7_ISH

@import MapKit.MKMapSnapshotter;

@interface MKMapSnapshotter (PromiseKit)
- (PMKPromise *)promise;
@end

#endif
