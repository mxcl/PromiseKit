#import <CoreLocation/CLGeocoder.h>
#import <PromiseKit/fwd.h>

@interface CLGeocoder (PromiseKit)
+ (PMKPromise *)reverseGeocode:(CLLocation *)location;
+ (PMKPromise *)geocode:(id)addressDictionaryOrAddressString;
@end
