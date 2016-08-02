#import <CoreLocation/CLGeocoder.h>
#import <PromiseKit/fwd.h>

/**
 To import the `CLGecoder` category:

    pod "PromiseKit/CLGeocoder"

 Or you can import all categories on `CoreLocation`:

    pod "PromiseKit/CoreLocation"
*/
@interface CLGeocoder (PromiseKit)

/**
 Submits a reverse-geocoding request for the specified location.

 @param location The location object containing the coordinate data to look up.

 @return A promise that thens two parameters:
 1. The first placemark that resides at the specified location.
 2. The array of *all* placemarks that reside at the specified location.
*/
+ (PMKPromise *)reverseGeocode:(CLLocation *)location;

/**
 Submits a forward-geocoding request using the specified address dictionary or address string.

 @param addressDictionaryOrAddressString The address dictionary or address string to look up.

 @return A promise that thens two parameters:
 1. The first placemark that resides at the specified address.
 2. The array of *all* placemarks that reside at the specified address.
*/
+ (PMKPromise *)geocode:(id)addressDictionaryOrAddressString;

@end
