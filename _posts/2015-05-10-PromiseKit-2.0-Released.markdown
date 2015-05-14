---
category: news
layout: news
---

<p><img style='width:100%' src="/public/img/PMKBanner2.png"></p>

<br>

Apple's Swift announcement was a jaw-dropper and meant big changes for PromiseKit, which, at that time, was still in its infancy. Shortly after the announcement, I jumped into Xcode and rocked out a Swift implementation of promises to see how they would feel. The compiler was a fearsome opponent but I emerged victorious with an implementation of type-safe promises. It was clear that they had their charm; however, we now had separate Swift and Objective-C promise implementations which couldn’t be bridged.

A solution to this situation wasn’t immediately obvious. Objective-C would never be able to use Swift promises because they were *generic*, and Swift could not (trivially) use our Objective-C promises because of their unusual method signature:

{% highlight objective-c %}
- (PMKPromise *(^)(id))then;
{% endhighlight %}

An unusual method signature that gives us special powers:

{% highlight objective-c %}
[self wait].then(^{
    return [self fetch];
}).then(^(NSArray *results){
    return [NSURLConnection GET:@"%"]
});
{% endhighlight %}

A dot-notated, chainable syntax that accepts variadic blocks! Super powerful and flexible, but Swift was not designed to cater to our edge case.

An ideal solution would allow promises to bridge from Swift to Objective-C and back, but not lose the compelling features of each.

## Our Solution

PromiseKit 2.0 has two promise types:

 * `Promise<T>` (Swift)
 * `AnyPromise` (Objective-C)
 
Each is designed to be an approproate promise implementation for the strong points of its language.

`Promise<T>` is strict, defined and precise. `AnyPromise` is loose, flexible and dynamic.

`AnyPromise` behaves like PromiseKit 1’s Objective-C promise implementation (`PMKPromise`):

{% highlight objective-c %}
[NSURLConnection GET:@"http://placekitten.org/%@/%@", width, height].then(^(UIImage *image){

    // PromiseKit determined the returned data was an image by
    // inspecting the HTTP response headers.

    self.imageView.image = image;
});

// or add optional parameters:

[NSURLConnection GET:…].then(^(UIImage *image, NSHTTPURLResponse* rsp, NSData *data){

    // With AnyPromise, adding parameters to your 'then' handler is
    // always safe. For the NSURLConnection category the extra
    // parameters will become the NSHTTPURLResponse and the raw
    // NSData response.

    self.imageView.image = image;
});
{% endhighlight %}

The stringency of `Promise<T>`, however, requires you to specify the data type you expect by specializing your `then`:

{% highlight swift %}
NSURLConnection.GET("http://placekitten.com/\(width)/\(height)").then { (image: UIImage) in
    self.imageView.image = image
}.catch { error in
    // If PromiseKit could not decode an image (for example, if you made
    // a mistake and the endpoint actually provides JSON), then Promise<T>
    // errors. AnyPromise would instead `then` a JSON NSDictionary, and if
    // you then tried to set the imageView’s image to that dictionary,
    // your code would crash.
}

// But if you want just data, you need only ask for data:

NSURLConnection.GET("http://placekitten.com/\(width)/\(height)").then { (data: NSData) in
    self.imageView.image = UIImage(data: image)
}
{% endhighlight %}


# 2.0 Features

## Bridging Promises

If you have an `AnyPromise` you can use it in a `Promise<T>` chain:

{% highlight swift %}
import PromiseKit.SystemConfiguration

NSURLConnection.POST(url, multipartFormData: formData).then {
    return SCNetworkReachability()
}.then { (obj: AnyObject?) in
    // AnyPromise always resolves with `AnyObject?`
}
{% endhighlight %}

Objective-C can’t **see** instances of generic classes, so if we wanted to bridge a `Promise<T>` our only option is to write some Swift:

{% highlight swift %}
class MyObject {
    func promise() -> Promise<MyObjectResponse> {
        return Promise { fulfill, reject in
            //…
        }
    }
    
    @objc public func promise() -> AnyPromise {
        return AnyPromise(bound: promise())
    }
}
{% endhighlight %}
    
## Cancellation

PromiseKit now supports the idea of cancellation.

If the underlying asynchronous task that the promise represents can be cancelled, then the author of that promise can register a specific error domain/code pair with PromiseKit. That error, then, will not trigger a catch handler. Here’s an example using an alert view:

{% highlight swift %}
let alert = UIAlertView(…)
alert.promise().then {
    // continue
}.catch {
    // this handler won’t execute if the user pressed cancel
}
{% endhighlight %}

This is typically what you want. If an alert is part of a chain and the user taps a button other than cancel, the chain will continue; however, if the user cancels, you want to abort the chain. But since the user explicitly cancelled the operation, you don’t want to run a catch handler that shows an error message.

You can opt-in to catch cancellation. Here’s a more elaborate example where cancellation is caught:

{% highlight swift %}
UIApplication.sharedApplication().networkActivityIndicatorVisible = true

NSURLConnection.GET(url).then {
    //…
    return UIAlertView(…).promise()
}.then {
    //…
}.catch(policy: .AllErrors) { error in
    if error.cancelled {
        //…
    } else {
        //…
    }
}.finally {
    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
}
{% endhighlight %}

The PromiseKit categories have all been amended to handle cancellation for types that support it.

As an added bonus, you can now quickly cancel any chain:

{% highlight objective-c %}
[NSURLConnection GET:url].then(^{
    //…
}).then(^{
    @throw [NSError cancelledError];
}).then(^{
    //…
});
{% endhighlight %}

This can conveniently and elegantly replace rightward drift inside your chain, and you won’t need to remember to ignore some magical thrown-in value in your `catch` handlers.

## `recover`

To work around [ambiguity](https://github.com/mxcl/PromiseKit/issues/56) in `catch` we provide the alternatively named `recover` for `Promise<T>`:
    
{% highlight swift %}
promise.then {
    return CLLocationManager.promise()
}.recover { error -> Promise<CLLocation> in
    if error.domain == kCLErrorDomain && error.code == kCLErrorRestricted {
        return Promise(CLChicagoLocation)
    } else {
        return Promise(error)
    }
}.then { location in
    //…
}
{% endhighlight %}

With `AnyPromise`, `catch` itself (as before) can be used in this manner:

{% highlight objective-c %}
promise.then(^{
    return [CLLocationManager promise];
}).catch(^id(NSError *error) {
    if ([error.domain == kCLErrorDomain && error.code == kCLErrorRestricted) {
        return CLChicagoLocation
    } else {
        return error
    }
}).then(^(CLLocation *location) {
    //…
})
{% endhighlight %}

Note that `recover` always receives cancellations.


## `zalgo` and `waldo`

Promises always execute `then` handlers via <abbr title='Grand Central Dispatch'>GCD</abbr> (by default on the main queue). We provide `zalgo` and `waldo` for high performance situations where this slight delay must be avoided.

<center class="big" style="font-size: 1.1rem">
Please note, there are <a href="http://blog.izs.me/post/59142742143/designing-apis-for-asynchrony">excellent reasons</a> why you should never use <code>zalgo</code>. We provide it (mostly) for library authors who use promises. In such situations you should write tests to verify that you have not created possible race conditions.
</center>

Normally a `then` can be dispatched to the queue of your choice:

{% highlight swift %}
let bgq = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

NSURLConnection.GET(url).then(on: bgq) {
    // we’re on the queue we asked for
}
{% endhighlight %}

Thus to zalgo we:

{% highlight swift %}
NSURLConnection.GET(url).then(on: zalgo) {
    // we will execute on the queue that the previous promise
    // resolved thus consider the queue completely *undefined*
}
{% endhighlight %}

Because the queue we execute on is undefined we provide `waldo`, which will unleash zalgo unless the queue is the main queue. In that case, we dispatch to the default background queue.

Again, **please** don’t use these in a misguided attempt to improve performance; the performance gain is negligible. We provide them for situations when it is imperative that there is minimal delay and for libraries that should be as performant as possible.


# Other Niceties

## `firstly`

Readability can be improved for simple chains if all promises are at the same level of indentation:

{% highlight swift %}
firstly {
    CLLocationManger.promise()
}.then {
    UIView.animate { foo.alpha = 1 }
}.then {
    NSURLConnection.POST(url)
}
{% endhighlight %}

## 100% Test Coverage

PromiseKit 1.x was well tested, and includes a port of the entire Promises/A+ testsuite. PromiseKit 2.x has tests wherever possible, including testing categories that typically involve user interaction.


## Carthage Support

PromiseKit 1.x supports Carthage (though only for Swift), but you end up having all the categories compiled in and thus your application links against almost all system frameworks (which is rarely desired). PromiseKit 2’s xcodeproj only builds `CorePromise`. If you choose to use Carthage you will have to copy any categories into your sources in order to use them. Carthage will check out the category sources into `/Carthage/Checkouts/PromiseKit/Categories` for you.

CocoaPods, as ever, will compile categories into the framework itself, and since they are all subspecs, you can pick and choose which ones you get. By default, CocoaPods will only bundle the `Foundation` and `UIKit` categories.


# Caveats In Use

## `@import`

We worked hard to make a single framework that has a different public interface for Objective-C and Swift so you get the completion you need and not completion you don’t. The single caveat to this is that in `.m` files you must import with the old syntax:

{% highlight objective-c %}
#import <PromiseKit/PromiseKit.h>

// using @import will not break anything, but it will not
// import everything either:

@import PromiseKit;

// so if you must use it, use both:
@import PromiseKit;
#import <PromiseKit/PromiseKit.h>
{% endhighlight %}

With Swift, simply `import PromiseKit` as you would expect.

## Swift Compiler Issues

The Swift compiler will often error with `then`. To figure out the issue, first
try specifying the full signature for your closures:

{% highlight swift %}
foo.then {
    doh()
    return bar()
}

// will need to be written as:

foo.then { obj -> Promise<Type> in
    doh()
    return bar()
}

// Because the Swift compiler cannot infer closure types very
// well yet, one-line closures almost always
// compile without explicitness. I’m not a fan of this, as it makes
// using promises in Swift ugly, but I hope that
// Apple intend to improve the detection of closure types to
// make using promises in Swift as delightful as in Objective-C.

foo.then {
    return bar()
}
{% endhighlight %}

If that doesn’t work, it’s probably unhappy about the syntax inside the closure. It has become confused and is blaming the syntax of your `then`. Move the code out of the closure and try to compile it at the level of a plain function. When it is fixed, move it back.

If you have further issues, feel free to open a ticket **with a screenshot** of
the error. Hopefully Swift 1.3 will be better with our kind of
usage.

It is notable that a lot of our above examples won’t compile right now, and
we are hopeful that this is just temporary.

## AnyPromise Resolves With `AnyObject?`

Because `AnyPromise` is for Objective-C, it can only hold objects that Objective-C can understand. Thus if it cannot be `id` it cannot resolve an `AnyPromise`.

# Porting Considerations

When porting from PromiseKit 1.x to 2.x, your code will probably compile as before. However, you should be aware of:

* Cancellation
* `AnyPromise` no longer catches most exceptions. You can still `@throw` strings and `NSError` objects. We decided that exceptions in Objective-C mostly represent serious programmer errors and should be allowed to crash the program. [Discussion here](https://github.com/mxcl/PromiseKit/issues/13)
* `PMKPromise` will continue to work as a namespace, but is considered deprecated.
* Features like `when` have been moved to top-level functions (e.g., `[PMKPromise when:]` is now `PMKWhen`). For Swift, they are the same (`when`, `join`, etc.).
* `PMKJoin` has a different parameter order per the documentation.
* PromiseKit 2.0 has an iOS 7 minimum deployment target, though for users who want convenience, it is 8.0. This is because CocoaPods and Carthage will only build Swift projects for iOS 8. We intend to explore building a static library that will work on iOS 7, so stay tuned if you’re using PromiseKit 2 on iOS 7 and don’t want to manually compile the framework. The other option is PromiseKit 1.x which (provided you don’t use the Swift version) supports back to iOS 6.
* Few exceptions are caught by `AnyPromise`. Because we explicitly encouraged it in the PromiseKit 1.x documentation, we still catch thrown `NSString` objects and thrown `NSError` objects. As before, `Promise<T>` will not catch anything since you can’t throw nor can you catch anything in Swift.
* PromiseKit 2 is mostly written in Swift. This means you will have to check the relevant project settings to embed a Swift framework.

In a few months we will delete the Swift portion of PromiseKit 1.x (CocoaPods will still find it if you depend on PromiseKit 1.x). It was never officially endorsed, and 2.x is better inevery way.


# The Future

PromiseKit is under active development and is used in hundreds of apps on the store. We will continue to improve and maintain it with your continued support!

[PromiseKit on Github](https://github.com/mxcl/PromiseKit)