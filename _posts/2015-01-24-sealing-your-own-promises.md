---
category: docs
layout: default
---

# Sealing Your Own Promises

To start your own promise chain, use `+promiseWithResolverBlock:`. Here we show how to wrap a [Parse](http://parse.com) query:

{% highlight objectivec %}
- (PMKPromise *)users {
    return [PMKPromise promiseWithResolverBlock:^(PMKResolver *resolve) {
        PFQuery *query = [PFUser query];
        [query whereKey:@"name" equals:@"mxcl"];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            resolve(error ?: objects);
        }];
    }];
}

[self users].then(^(NSArray *users){
    //…
});
{% endhighlight %}

`resolve` rejects the promise if you pass an NSError and fulfills it otherwise. It’s very important that all asynchronous paths end with a resolve or your promise will hang.

This unusual syntax (for Objective-C) encourages encapsulation. `resolve` is private and should not be generally accessible to outside code. Thus if you use promises returned from third party code you can feel confident that they are not being mutated by your code or by anything else. It also means exceptions thrown during creation will be caught and cause the promise to be immediately rejected.

Often you may need to do some work in a background queue as part of your new promise; if so, don’t be afraid to start using `thenOn` or `thenInBackground`. `then` and `thenOn`, return new promises, so you can just return that promise instead of the initial promise, and your API is A-OK.

{% highlight objectivec %}
- (PMKPromise *)kittens {
    return [PMKPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [KittenPower fetch:^(NSArray kittens){
            resolve(kittens);
        }];
    }].thenInBackground(^(NSArray *kittens){
        for (Kitten *kitten in kittens) {
            [kitten fetchImageSynchronously];
        }
        return kittens;
    });
}
{% endhighlight %}

Here we synchronously fetched the kitten images in a background queue, then returned the same array again.

If you immediately need to work in the background we provide `dispatch_promise`.

<div><a class="pagination" href="/retain-cycle-considerations">Next: Retain Cycle Considerations</a></div>
