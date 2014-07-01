#import "PromiseKit/fwd.h"

#if PMK_MODULES
  @import CoreLocation.CLLocationManager;
  @import CoreLocation.CLGeocoder;
#else
  #import <CoreLocation/CoreLocation.h>
#endif


@interface CLLocationManager (PromiseKit)

/**
 Determines the user’s location and then's it.

 Since the delegate gives us an array of locations, we then the most
 recent location, and then the whole array as the second parameter.

 If the user has not yet authorized your app to monitor the location of
 the phone and this is iOS 8, we wait for the user to authorize the app
 to locate the user *during use*. If you don’t want during use then you
 must write your own promise. Please submit your work back to PromiseKit.
*/
+ (PMKPromise *)promise;

@end


@interface CLGeocoder (PromiseKit)
+ (PMKPromise *)reverseGeocode:(CLLocation *)location;
+ (PMKPromise *)geocode:(id)addressDictionaryOrAddressString;
@end
