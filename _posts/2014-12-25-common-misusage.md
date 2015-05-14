---
category: home
layout: default
---

# Common Misusage

Here a few common misusages of promises that are worth avoiding.

## Superfluous use of `+new:`

When you already have a promise, you don’t need `+promiseWithResolverBlock:`, `+promiseWithResolverBlock:` is only required when you are wrapping something that is *not* a promise. So don’t do this:

{% highlight objectivec %}
- (PMKPromise *)fetchParseAndStore {
    return [PMKPromise promiseWithResolverBlock:^(PMKResolver resolve){
        [Thing fetch].then(^(id result){
            return [Thing parse:result];
        }).then(^(id result){
            return [Thang store:result];
        }).then(^(id result){
            resolve(result);
        }).catch(^(NSError *error){
            resolve(error);
        });
    }];
}
{% endhighlight %}

Instead do this:

{% highlight objectivec %}
- (PMKPromise *)fetchParseAndStore {
    return [Thing fetch].then(^(id result){
        return [Thing parse:result];
    }).then(^(id result){
        return [Thang store:result];
    });
}
{% endhighlight %}

You already *had* a promise, so there’s no need to wrap it in *another*
promise.

Although it is worth noting, that we could have just passed `resolve` straight to `then` and `catch`. This is a handy trick on ocassion negating the need for a block to wrap a single call to a block:

{% highlight objectivec %}
- (PMKPromise *)fetchParseAndStore {
    return [PMKPromise promiseWithResolverBlock:^(PMKResolver resolve){
        [Thing fetch].then(^(id result){
            return [Thing parse:result];
        }).then(^(id result){
            return [Thang store:result];
        }).then(resolve).catch(resolve);
     }];
}
{% endhighlight %}
 
However we are demonstrating this for instructional purposes. With the
above situation, don’t use `+promiseWithResolverBlock:`.

## Starting a Promise Chain with `dispatch_promise`

{% highlight objectivec %}
dispatch_promise(^{
    // noop
}).then(^{
    return [NSURLConnection GET:url];
}).then(^{
    return foo;
}).then(^{
    //…
});
{% endhighlight %}

The `dispatch_promise` is superfluous. Instead just chain straight off the promise from `NSURLConnection`:

{% highlight objectivec %}
[NSURLConnection GET:url].then(^{
    //…
}).then(^{
    return foo;
}).then(^{
    //…
});
{% endhighlight %}

 
<div><a class="pagination" href="/appendix">Next: Appendix</a></div>

