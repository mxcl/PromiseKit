---
category: docs
layout: default
---

# Wrapping a Delegate Pattern

Be cautious when wrapping delegate systems, Promises are **one shot**: they resolve once. Most delegate methods are able to be called more than once.

Consequently PromiseKit doesn’t wrap many delegate patterns yet (eg. `UITextFieldDelegate` is not really appropriate) and where we do wrap them we have to do some anti-ARC hacks to prevent the delegating object from being prematurely released.

{% highlight objectivec %}
@implementation CLLocationManager (PromiseKit)

+ (PMKPromise *)promise {
    return [PMKLocationManager promise];
}

@end

@interface PMKLocationManager : CLLocationManager <CLLocationManagerDelegate>
@end

@implementation PMKLocationManager {
    PromiseFulfiller fulfiller;   // void (^)(id)
    PromiseRejecter rejecter;     // void (^)(NSError *)
}

+ (PMKPromise *)promise {
    PMKLocationManager *manager = [PMKLocationManager new];
    manager.delegate = manager;
    [manager startUpdatingLocation];
    PMKPromise *promise = [Promise new:^(PromiseFulfiller fulfiller, PromiseRejecter rejecter){
        manager->fulfiller = fulfiller;
        manager->rejecter = rejecter;
    }];
    promise.finally(^{
        /*
          By using the manager object here we force it to be retained by the
          Promise object until *after* the part of the chain that uses it has
          finished. Logging sucks, so maybe there is something more useful you can
          do, eg. for `CLLocationManager` `-stopUpdatingLocation` would be perfect!
          If you have nothing, then see the PromiseKit sources, we use an
          associated object hack to force an object to retain itself.
         */
        NSLog(@"%@", manager);
    });
}

- (void)locationManager:(id)manager didUpdateLocations:(NSArray *)locations {
    fulfiller(PMKManifold(locations.firstObject, locations));
}

- (void)locationManager:(id)manager didFailWithError:(NSError *)error {
    rejecter(error);
}

@end
{% endhighlight %}

<div><a class="pagination" href="/partial-recovery">Next: Partial Recovery</a></div>
