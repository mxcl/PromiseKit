@import CoreLocation.CLLocationManager;
@class Promise;


@interface CLLocationManager (PromiseKit)
+ (Promise *)promise;
@end
