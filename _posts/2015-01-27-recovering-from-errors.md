---
category: docs
layout: default
---

# Recovering From Errors

You can return from an error handler. Returning anything but an `NSError` implies the error has been resolved, and the chain will continue.

{% highlight objectivec %}

[CLLocationManager promise].catch(^(NSError *error){
    return CLLocationChicago;
}).then(^(CLLocation *userLocation){
    // the user’s location, or Chicago if an error occurred
});

{% endhighlight %}

This is useful for error-correction. If the error is fatal, then return the error again, or return a new `NSError`.

Usually when you decide to implement “recovery” you will need to change the return type of the block to `id`. Clang is smart about automatically determining the return type of blocks, but when you return two different types, it stubbornly insists you specify `id`. For example:


{% highlight objectivec %}

[CLLocationManager promise].catch(^id(NSError *error){
    if (error.code == CLLocationUnknown) {
        return CLLocationChicago;
    } else {
        return error;
    }
}).then(^(CLLocation *userLocation){
    // the user’s location, or Chicago for specific errors
}).catch(^{
    // errors that were not recovered above
});

{% endhighlight %}


<div><a class="pagination" href="/breaking-the-chain">Next: Instigating Errors</a></div>
