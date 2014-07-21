---
category: home
layout: default
---

# Intermediate Promises

## Using `-finally`

`finally` always executes its block, rejected and fulfilled both.

{% highlight objectivec %}
[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

[NSURLConnection GET:@"http://placekitten.com/320/320"].then(^(UIImage *image){
    self.imageView = image;
}).finally(^{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
});
{% endhighlight %}


## Sealing Your Own Promises

To start your own promise chain, use `+new:`. Here we show how to wrap a [Parse](http://parse.com) query:

{% highlight objectivec %}
- (PMKPromise *)users {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        PFQuery *query = [PFUser query];
        [query whereKey:@"name" equals:@"mxcl"];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (error) {
                reject(error);
            } else {
                fulfill(objects);
            }
        }];
    }];
}

[self users].then(^(NSArray *users){
    //…
});
{% endhighlight %}

Call `fulfill` if the asynchronous operation succeeds, and `reject` if it fails.

This unusual syntax (for Objective-C) encourages encapsulation. `fulfill` and `reject` are private and should not be generally accessible to outside code. Thus if you use promises returned from third party code you can feel confident that they are not being mutated by your code or by anything else. It also means exceptions thrown during creation will be caught and cause the promise to be immediately rejected.


## Choosing Your Execution Context (`-thenOn`, …)

`then` always executes on the main thread. If you want to control where your block is executed use `thenOn` which takes a `dispatch_queue_t` as its first parameter:

{% highlight objectivec %}
id url = @"http://placekitten.com/320/320";
id q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
[NSURLConnection GET:url].thenOn(q, ^(UIImage *image){
    assert(![NSThread isMainThread]);
});
{% endhighlight %}

There are also `finallyOn` and `catchOn`.


## Thread Safety

PromiseKit is thread-safe. Fulfill, return and work in whatever threads you like, subsequent thens, catches and finallys will run on the thread specified, ie. `-then` runs on the main queue, `thenOn` runs on the queue you specify.


## Resolving Promises with Multiple Values

PromiseKit allows Promises to resolve with multiple values. The `NSURLConnection` categories are good examples of this:

{% highlight objectivec %}
id url = @"http://placekitten.com/320/320";
[NSURLConnection GET:url].then(^(UIImage *img, NSHTTPURLResponse *rsp, NSData *rawData){
    //…
});
{% endhighlight %}

Crucially, all parameters in promises are optional. Usually you don’t want or need the HTTPURLResponse or the undecoded rawData, but when you do, you can adjust the then block and receive them.

In order to make your own promises resolve with more than one value you use `PMKManifold`:

{% highlight objectivec %}
- (PMKPromise *)somePromise {
    return [Promise new:^(PromiseFulfiller fulfiller, PromiseRejecter rejecter) {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            id p1 = doWork();
            id p2 = doMoreWork();
            id p3 = doEvenMoreWork();
            fulfiller(PMKManifold(p1, p2, p3));
        });
    }];
}
{% endhighlight %}
