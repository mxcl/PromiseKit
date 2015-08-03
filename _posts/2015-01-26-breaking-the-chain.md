---
category: docs
layout: default
---

<h1>Triggering Errors — Objective C</h1>

To fail an `AnyPromise` chain `@throw` an `NSError` object:

{% highlight objectivec %}

[NSURLConnection GET:@"http://placekitten.com/300/300"].then(^(UIImage *kittenImage){
    if ([self looksLikeFrog:kittenImage]) {
        @throw [NSError errorWithDomain:… code:… userInfo:…];

    return [self processImage:kittenImage];
});

{% endhighlight %}

For convenience you can also `@throw` an `NSString *`, but avoid this if possible as it leads to hard-to-trace errors.

Note that returning an error from any promise handler will also reject that promise.


<h1>Triggering Errors — Swift</h1>

To fail a `Promise<T>` chain, `throw`:

{% highlight swift %}

enum Error: ErrorType {
    case LooksLikeFrog(UIImage)
    case …
}

NSURLConnection.GET("http://placekitten.com/300/300").then { (image: UIImage) in
    guard !looksLikeFrog(image) else {
        throw Error.LooksLikeFrag(image)
    }
    return processKittenImage(image)
}

{% endhighlight %}

<div><a class="pagination" href="/tuples">Next: Resolving with Tuples</a></div>
