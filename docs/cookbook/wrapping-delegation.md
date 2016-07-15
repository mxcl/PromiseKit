---
layout: docs
redirect_from: "/wrapping-delegation/"
---

# Wrapping a Delegate Pattern

Be cautious when wrapping delegate systems, Promises are **one shot**: they resolve once. Most delegate methods are able to be called more than once.

Consequently PromiseKit doesn’t wrap many delegate patterns yet (eg. `UITextFieldDelegate` is not really appropriate) and where we do wrap them we have to do some anti-ARC hacks to prevent the delegating object from being prematurely released.

```objc
@implementation CLLocationManager (PromiseKit)

+ (PMKPromise *)promise {
    return [PMKLocationManager promise];
}

@end

@interface PMKLocationManager : CLLocationManager <CLLocationManagerDelegate>
@end

@implementation PMKLocationManager {
    PMKResolver resolve;
    id retainCycle;
}

+ (PMKPromise *)promise {
    PMKLocationManager *manager = [PMKLocationManager new];
    manager.delegate = manager;
    manager->retainCycle = self;  // prevent deallocation
    [manager startUpdatingLocation];
    return [[AnyPromise alloc] initWithResolve:&manager->resolve];
}

- (void)locationManager:(id)manager didUpdateLocations:(NSArray *)locations {
    resolve(PMKManifold(locations.firstObject, locations));
    retainCycle = nil;  // break retain cycle
}

- (void)locationManager:(id)manager didFailWithError:(NSError *)error {
    resolve(error);
    retainCycle = nil;  // break retain cycle
}

@end
```