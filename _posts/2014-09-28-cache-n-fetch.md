---
category: examples
layout: default
---

# Cache & Fetch

In the case where you have the persisted, cached value for some asynchronous object and you want to show the user that, but also fetch the fresh data and then show the user that:

{% highlight objectivec %}
- (PMKPromise *)fetch {
    return [Promise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter rejct){
        id fresh = [NSURLConnection GET:self.fetchURL];  // start fetching ASAP
        id cached = [NSData dataWithContentsOfFile:…];
        fulfill(PMKManifold(cached, fresh));
    }];
}

- (void)go {
    self.fetch.then(^(NSData *cachedData, PMKPromise *freshData) {
        [self updateWithData:cachedData];
        return freshData;
    }).then(^(NSData *freshData){
        [self updateWithData:freshData];
    });
}
{% endhighlight %}

Wrapping a promise in `PMKManifold` does **not** cause the chain to wait on that promise. Which means it works for the above usage. If you want a wait, use `when`.

<div><a class="pagination" href="/abstracting-away-asynchronicity">Next: Abstracting Away Asynchronicity</a></div>
