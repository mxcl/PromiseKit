---
category: docs
layout: default
---

<h1>Triggering Errors</h1>

If you have need to cause your own error in a promise chain, just return an NSError object:

{% highlight objectivec %}

[NSURLConnection GET:@"http://placekitten.com/300/300"].then(^id(UIImage *kittenImage){
    if ([self looksLikeFrog:kittenImage]) {
        return [NSError errorWithDomain:… code:… userInfo:…];
    } else {
        return [self processImage:kittenImage];
    }
});

{% endhighlight %}

Throwing an exception always rejects that promise. It is often more convenient during development to just `@throw` rather than make the effort to construct a full and proper `NSError` object.

{% highlight objectivec %}

[NSURLConnection GET:@"http://placekitten.com/300/300"].then(^(UIImage *kittenImage){
    if (![self looksLikeFrog:kittenImage])
        @throw @"OPOO"
    return [self processImage:kittenImage];
});

{% endhighlight %}

`catch` always provides an `NSError`, so in the case where you (or some other library) throws you will get an NSError with the thrown object’s `description` set as the error’s `localizedDescription` property and the thrown object itself set as the  `PMKUnderlyingExceptionKey` key of the error’s `userInfo`.

It’s unlikely an exception would generate a string that is suitable for end-user display. With this in mind it is always better to try to generate detailed, proper `NSError` objects when errors happen in your promises. PromiseKit makes good error handling *easy*, it would be a pity to spoil this bonus to user-experience by not showing a good error message.

<aside>PromiseKit itself provides <i>excellent</i> error messages for all situations it handles <code>:)</code></aside>

<div><a class="pagination" href="/tuples">Next: Resolving with Tuples</a></div>
