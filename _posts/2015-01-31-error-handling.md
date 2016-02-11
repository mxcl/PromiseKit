---
category: docs
layout: default
---

# Error Handling. Like a Boss.

Error handling is notoriously hard; asynchronous error handling can be downright outrageous. The result is a shameful number of unhandled errors in modern codebases.

{% highlight objectivec %}
void (^errorHandler)(NSError *) = ^(NSError *error) {
    [[UIAlertView …] show];
};
[NSURLConnection sendAsynchronousRequest:rq queue:q completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
    if (connectionError) {
        errorHandler(connectionError);
    } else {
        NSError *jsonError = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError) {
            errorHandler(jsonError);
        } else {
            id rq = [NSURLRequest requestWithURL:[NSURL URLWithString:json[@"avatar_url"]]];
            [NSURLConnection sendAsynchronousRequest:rq queue:q completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                UIImage *image = [UIImage imageWithData:data];
                if (!image) {
                    errorHandler(nil); // NSError TODO!
                } else {
                    self.imageView.image = image;
                }
            }];
        }
    }
}];
{% endhighlight %}

This isn't even a complicated example.

Promises streamline error handling:

{% highlight objectivec %}
[NSURLSession GET:url].then(^(NSDictionary *json){
    return [NSURLConnection GET:json[@"avatar_url"]];
}).then(^(UIImage *image){
    self.imageView.image = image;
}).catch(^(NSError *error){
    [[UIAlertView …] show];
})
{% endhighlight %}

{% highlight swift %}
firstly {
    NSURLSession.GET(url)
}.then { (json: NSDictionary) in
    NSURLConnection.GET(json["avatar_url"])
}.then { (image: UIImage) in
    self.imageView.image = image
}.error { error in
    UIAlertView(…).show()
}
{% endhighlight %}


Any errors that happen anywhere in the chain propogate to the error handler skipping any intermediary `then` handlers.

<aside>This is a somewhat unfair example: PromiseKit’s Objective-C <code>NSURLSession</code> category detects the JSON and the image HTTP responses and automatically decode them for you (with thoroughly filled <code>NSError</code> objects). The Swift version does not detect, but you still get decoded responses by specializing the then to the response type you want.</aside>

It’s important to remember that in order for your errors to propogate they must occur in the chain. **If you don’t return your promise, thus inserting it into the chain, the error won’t propogate**.

PromiseKit has an additional bonus: unhandled errors (ie. errors that never get handled in a `catch`, `error`, or `recover`) are logged. If you like, we even provide [a mechanism][ueh] to execute your own code whenever errors are not caught.

<div><a class="pagination" href="/when">Next: `when`</a></div>

[ueh]: https://github.com/mxcl/PromiseKit/blob/master/Sources/ErrorUnhandler.swift#L3-L24