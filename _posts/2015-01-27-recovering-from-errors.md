---
category: docs
layout: default
---

# Recovering From Errors — Objective C

Returning from `catch` continues the chain. Returning anything but an `NSError` implies the error has been resolved, and thus the chain will continue.

{% highlight objectivec %}

[CLLocationManager promise].catch(^(NSError *error){
    return CLLocationChicago;
}).then(^(CLLocation *userLocation){
    // the user’s location, or Chicago if an error occurred
});

{% endhighlight %}

This is useful for error-correction. If the error is fatal, then “rethrow” the error or `@throw` a new `NSError`:

{% highlight objectivec %}

[CLLocationManager promise].catch(^(NSError *error){
    if (IsFatal(error)) @throw error;
    return CLLocationChicago;
}).then(^(CLLocation *userLocation){
    //…
}).catch(^(NSError *error){
    // error was fatal
});

{% endhighlight %}


# Recovering From Errors — Swift

Swift `catch` is terminating (the chain cannot continue), instead we provide `recover`:

{% highlight objectivec %}

CLLocationManager.promise().recover { err in
    guard !err.fatal else { throw err }
    return CLLocationChicago
}.then { location in
    // the user’s location, or Chicago if an error occurred
}.catch { err in
    // the error was fatal
}

{% endhighlight %}



<div><a class="pagination" href="/breaking-the-chain">Next: Instigating Errors</a></div>
