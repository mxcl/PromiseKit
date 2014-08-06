#import <CoreLocation/CLLocationManagerDelegate.h>
#import "CLLocationManager+PromiseKit.h"
#import <objc/runtime.h>
#import "PromiseKit/Promise.h"

@interface PMKLocationManager : CLLocationManager <CLLocationManagerDelegate>
@end



@implementation PMKLocationManager {
@public
    void (^fulfiller)(id);
    void (^rejecter)(id);
}

#define PMKLocationManagerCleanup() \
    [manager stopUpdatingLocation]; \
    self.delegate = nil; \
    PMKRelease(self);

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    fulfiller(PMKManifold(locations.lastObject, locations));
    PMKLocationManagerCleanup();
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    rejecter(error);
    PMKLocationManagerCleanup();
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [manager startUpdatingLocation];
}

@end



@implementation CLLocationManager (PromiseKit)

+ (PMKPromise *)promise {
    PMKLocationManager *manager = [PMKLocationManager new];
    manager.delegate = manager;
    PMKRetain(manager);

  #if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wundeclared-selector"
    SEL sel = @selector(requestWhenInUseAuthorization);
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined && [manager respondsToSelector:sel]) {
        [manager performSelector:sel];
    } else {
        [manager startUpdatingLocation];
    }
  #else
    [manager startUpdatingLocation];
  #pragma clang diagnostic pop
  #pragma clang diagnostic pop
  #endif

    return [PMKPromise new:^(id fulfiller, id rejecter){
        manager->fulfiller = fulfiller;
        manager->rejecter = rejecter;
    }];
}

@end
