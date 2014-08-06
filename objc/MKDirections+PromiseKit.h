#import <MapKit/MKDirections.h>
#import "PromiseKit/fwd.h"

@interface MKDirections (PromiseKit)
+ (PMKPromise *)promise:(MKDirectionsRequest *)request;
+ (PMKPromise *)promiseETA:(MKDirectionsRequest *)request;
@end
