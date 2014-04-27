@import CoreLocation.CLLocationManager;
@import CoreLocation.CLGeocoder;
@class Promise;


@interface CLLocationManager (PromiseKit)
+ (Promise *)promise;
@end


@interface CLGeocoder (PromiseKit)
+ (Promise *)reverseGeocode:(CLLocation *)location;
+ (Promise *)geocode:(id)addressDictionaryOrAddressString;
@end
