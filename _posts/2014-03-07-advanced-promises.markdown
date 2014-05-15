---
category: home
layout: default
---

# Advanced Promises

## Unusually Tolerant Syntax

The block you pass to `then` or `catch` can have return type of `Promise`, or any object, any primitive, or nothing. And it can have a parameter of `id`, or a specific class type, or nothing, or even multiple parameters (if the previous Promise fulfilled with multiple values).

So all of these are valid however `myPromise` is resolved:

{% highlight objectivec %}
myPromise.then(^{
    // no return
});

myPromise.then(^(id obj){
    // no return
});

myPromise.then(^(id obj){
    return @1;
});

myPromise.then(^{
    return @2;
});
{% endhighlight %}

Clang is smart so you don’t (usually) have to specify a return type for your block.

This is not usual to Objective-C or blocks. Usually everything is very explicit. We are using introspection to determine what arguments and return types you are working with. Thus, programming with PromiseKit has similarities to programming with (more) modern languages like Ruby or Javascript.

<aside>If you return two different types in your block you will have to specify an `id` return type for your block. Usually this is necessary if you are returning an `NSError` and some other object elsewhere in your block.</aside>

In fact these (and more) are also fine:

{% highlight objectivec %}
myPromise.then(^{
    return 1;
}).then(^(NSNumber *n){
    assert([n isEqual:@1]);
});

myPromise.then(^{
    return false;
}).then(^(NSNumber *n){
    assert([n isEqual:@NO]);
});
{% endhighlight %}


## Wrapping a Delegate Pattern

Be cautious when wrapping delegate systems, Promises are **one shot**: they resolve once. Most delegate methods are able to be called more than once.

Consequently PromiseKit doesn’t wrap many delegate patterns yet (eg. `UITextFieldDelegate` is not really appropriate) and where we do wrap them we have to do some anti-ARC hacks to prevent the delegating object from being prematurely released.

{% highlight objectivec %}
@implementation CLLocationManager (PromiseKit)

+ (PMKPromise *)promise {
    [PMKLocationManager promise];
}

@end

@interface PMKLocationManager : CLLocationManager <CLLocationManagerDelegate>
@end

@implementation PMKLocationManager {
    PromiseFulfiller fulfiller;  // void (^)(id)
    PromiseRejecter rejecter;    // void (^)(NSError *)
}

+ (PMKPromise *)promise {
    PMKLocationManager *manager = [PMKLocationManager new];
    manager.delegate = manager;
    [manager startUpdatingLocation];
    [manager pmk_reference];  // anti ARC hack
    return [Promise new:^(PromiseFulfiller fulfiller, PromiseRejecter rejecter){
        manager->fulfiller = fulfiller;
        manager->rejecter = rejecter;
    }];
}

- (void)locationManager:(id)manager didUpdateLocations:(NSArray *)locations {
    fulfiller(PMKManifold(locations.firstObject, locations));
    [self pmk_breakReference];  // anti ARC hack
}

- (void)locationManager:(id)manager didFailWithError:(NSError *)error {
    rejecter(error);
    [self pmk_breakReference];  // anti ARC hack
}

@end
{% endhighlight %}
