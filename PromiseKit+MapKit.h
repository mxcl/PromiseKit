@import MapKit.MKMapSnapshotter;
@import MapKit.MKDirections;
@class Promise;


@interface MKDirections (PromiseKit)
+ (Promise *)promise:(MKDirectionsRequest *)request;
+ (Promise *)promiseETA:(MKDirectionsRequest *)request;
@end

@interface MKMapSnapshotter (PromiseKit)
- (Promise *)promise;
@end
