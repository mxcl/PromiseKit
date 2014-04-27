@import CoreLocation.CLLocationManagerDelegate;
#import "Private/macros.m"
#import "PromiseKit+CoreLocation.h"
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
    __anti_arc_release(self);

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    fulfiller(locations.count == 1 ? locations[0] : locations);
    PMKLocationManagerCleanup();
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    rejecter(error);
    PMKLocationManagerCleanup();
}

@end



@implementation CLLocationManager (PromiseKit)

+ (Promise *)promise {
    PMKLocationManager *manager = [PMKLocationManager new];
    manager.delegate = manager;
    [manager startUpdatingLocation];
    __anti_arc_retain(manager);
    return [Promise new:^(id fulfiller, id rejecter){
        manager->fulfiller = fulfiller;
        manager->rejecter = rejecter;
    }];
}

@end
