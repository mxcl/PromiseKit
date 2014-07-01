#import "PromiseKit/fwd.h"



#if !PMK_MODULES
  #import <MapKit/MapKit.h>
#endif



#if PMK_iOS6_ISH

#if PMK_MODULES
  @import MapKit.MKDirections;
#endif

@interface MKDirections (PromiseKit)
+ (PMKPromise *)promise:(MKDirectionsRequest *)request;
+ (PMKPromise *)promiseETA:(MKDirectionsRequest *)request;
@end

#endif



#if PMK_iOS7_ISH

#if PMK_MODULES
  @import MapKit.MKMapSnapshotter;
#endif

@interface MKMapSnapshotter (PromiseKit)
- (PMKPromise *)promise;
@end

#endif
