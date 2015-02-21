#import <CoreLocation/CLLocationManager.h>
#import <PromiseKit/fwd.h>


@interface CLLocationManager (PromiseKit)

/**
 `then`s the user’s location.

 Since the delegate gives us an array of locations, we then the most
 recent location, and then the whole array as the second parameter.

 If the user has not yet authorized your app to monitor the location of
 the phone and this is iOS 8, we wait for the user to authorize the app
 to locate the user *during use*. If you don’t want during use then you
 must write your own promise. Please submit your work back to PromiseKit.

 This variant assumes you want a vertical and horizontal accuracy of
 at least 500 meters.
*/
+ (PMKPromise *)promise;


/**
 `then`s the user’s location once the provided block returns `YES` for
 at least one location.

 With this variant you can wait for good accuracy or accept bad
 accuracy (at your own determination) if the `CLLocationManager`
 is taking too long. For example, the user is not outside so you
 will never get 10 meter accuracy, but it would be nice to wait
 a little just in case.

 @see +promise
*/
+ (PMKPromise *)until:(BOOL(^)(CLLocation *))isLocationGoodBlock;

@end
