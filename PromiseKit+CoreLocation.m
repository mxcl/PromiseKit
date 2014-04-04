@import CoreLocation.CLLocationManagerDelegate;
#import "macros.m"
#import "PromiseKit+CoreLocation.h"
#import "PromiseKit/Deferred.h"
#import "PromiseKit/Promise.h"

@interface PMKLocationManager : CLLocationManager <CLLocationManagerDelegate>
@end



@implementation PMKLocationManager {
    Deferred *deferred;
}

- (id)init {
    self = [super init];
    deferred = [Deferred new];
    return self;
}

- (Promise *)promise {
    return deferred.promise;
}

#define PMKLocationManagerCleanup() \
    [manager stopUpdatingLocation]; \
    self.delegate = nil; \
    __anti_arc_release(self);

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    [deferred resolve:locations.count == 1 ? locations[0] : locations];
    PMKLocationManagerCleanup();
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [deferred reject:error];
    PMKLocationManagerCleanup();
}

@end



@implementation CLLocationManager (PromiseKit)

+ (Promise *)promise {
    PMKLocationManager *manager = [PMKLocationManager new];
    manager.delegate = manager;
    [manager startUpdatingLocation];
    __anti_arc_retain(manager);
    return manager.promise;
}

@end
