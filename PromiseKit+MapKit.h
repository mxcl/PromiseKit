#define PMK_DEPLOY_7 ((defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090) \
                   || (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000))

#if PMK_DEPLOY_7

@import MapKit.MKMapSnapshotter;
@import MapKit.MKDirections;
@class PMKPromise;


@interface MKDirections (PromiseKit)
+ (PMKPromise *)promise:(MKDirectionsRequest *)request;
+ (PMKPromise *)promiseETA:(MKDirectionsRequest *)request;
@end

@interface MKMapSnapshotter (PromiseKit)
- (PMKPromise *)promise;
@end

#endif
