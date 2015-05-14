---
category: docs
layout: default
---

<h1>Retain Cycle Considerations</h1>

tl;dr: it’s safe to use `self` in promise handlers.

Provided all your promises resolve, the handlers will be released, and any retain cycles caused by referencing `self` in your promise handlers will be dereferenced. This applies even if you hold a reference to the promise object as a class property (the handlers are released, and it is the handlers that are retaining `self`). So this does not cause a retain cycle:

{% highlight objectivec %}
somePromise.then(^{
    [self doSomething];
});
{% endhighlight %}

This is conveniently because promises are *one-shot*.

The exception would be if you store the promise handler as a strong property on your class, but that would be a strange thing to do. Don’t do that. This is an example of what you shouldn’t do:

{% highlight objectivec %}
self.handler = ^{
    [self doSomething];
};
somePromise.then(self.handler);
{% endhighlight %}

The above is a classic retain cycle. Don’t do that.

In cases where you think the promise will outlive the object that `self` refers to and you want that object to be deallocated, use weak references to `self`.

It’s easy to do code like this though, and this code has a retain cycle, though it’s not because of the promises:

{% highlight objectivec %}
[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification usingBlock:^(NSNotification *note) {
    [NSURLConnection GET:URL].then(^(id data){
        [self scan:data];
    })
}
{% endhighlight %}

It’s safe to reference `self` inside promise handlers, but that doesn’t mean promise chains within **other** blocks can safely reference `self`. Here `NSNotificationCenter` never relinquishes references to `self`—per Apple’s design. Be careful, in these sort of situations you need a *weak* reference to `self`.

<div><a class="pagination" href="/getting-started">Next: Getting Started With PromiseKit</a></div>
