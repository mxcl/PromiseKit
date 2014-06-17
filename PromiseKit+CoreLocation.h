@import CoreLocation.CLLocationManager;
@import CoreLocation.CLGeocoder;
@class PMKPromise;


@interface CLLocationManager (PromiseKit)
+ (PMKPromise *)promise;
@end


@interface CLGeocoder (PromiseKit)
+ (PMKPromise *)reverseGeocode:(CLLocation *)location;
+ (PMKPromise *)geocode:(id)addressDictionaryOrAddressString;
@end
