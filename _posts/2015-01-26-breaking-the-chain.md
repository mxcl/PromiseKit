---
category: docs
layout: default
---

<h1>Triggering Errors</h1>

If you have need to cause your own error in a promise chain, just return an NSError object:

{% highlight objectivec %}

[NSURLConnection GET:@"http://placekitten.com/300/300"].then(^(UIImage *kittenImage){
    if ([self looksLikeFrog:kittenImage]) {
        return [NSError errorWithDomain:… code:… userInfo:…];
    } else {
        return [self processImage:kittenImage];
    }
});

{% endhighlight %}

<div><a class="pagination" href="/tuples">Next: Resolving with Tuples</a></div>
