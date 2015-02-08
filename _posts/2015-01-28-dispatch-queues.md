---
category: docs
layout: default
---

<h1>Dispatch Queues</h1>

`then` always executes on the main queue since, mostly, this is what you want. However, you can easily continue on any queue you choose:

{% highlight objectivec %}

id url = @"http://placekitten.com/320/320";
id q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

[NSURLConnection GET:url].thenOn(q, ^(UIImage *image){
    assert(![NSThread isMainThread]);
});

{% endhighlight %}

With `thenOn` it becomes convenient to process data from promises off the main thread and then pass it back for `UIView` display.

{% highlight objectivec %}

[NSURLConnection GET:url].thenInBackground(^(NSArray *json){
    return OMGSuperExpensiveFunction(json);
}).then(^(NSArray *processedData){
    self.kittens = processedData;
    [self.tableView reloadData];
});

{% endhighlight %}

In the above example we used the convenience method `thenInBackground`, which dispatches the promise onto the default GCD queue.

<aside>Everything in PromiseKit is thread-safe.</aside>

There are also `finallyOn` and `catchOn`.

<hr>

If you find yourself writing `dispatch_async` in your promises code, then stop. Instead return and then use `thenOn`, this makes your code more extensible and improve readability by reducing rightward-drift.

<div><a class="pagination" href="/recovering-from-errors">Next: Error Recovery</a></div>
