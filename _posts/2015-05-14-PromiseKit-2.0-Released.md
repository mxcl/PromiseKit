---
layout: default
hidebanner: true
redirect_from: "/PromiseKit-2.0-Released/"
---
<br>

<p><img style='width:100%' src="/public/img/PMKBanner2.png"></p>

<br>

Apple's Swift announcement was a jaw-dropper and meant big changes for PromiseKit, which, at that time, was still in its infancy. Shortly after the announcement, I jumped into Xcode and rocked out a Swift implementation of promises to see how they would feel. The compiler was a fearsome opponent but I emerged victorious with an implementation of type-safe promises. It was clear that they had their charm; however, we now had separate Swift and Objective-C promise implementations which couldn’t be bridged.

A solution to this situation wasn’t immediately obvious. Objective-C would never be able to use Swift promises because they were *generic*, and Swift could not (trivially) use our Objective-C promises because of their unusual method signature:

```objc
- (PMKPromise *(^)(id))then;
```

An unusual method signature that gives us special powers:

```objc
[self wait].then(^{
    return [self fetch];
}).then(^(NSArray *results){
    return [NSURLConnection GET:@"%"]
});
```

A dot-notated, chainable syntax that accepts variadic blocks! Super powerful and flexible, but Swift was not designed to cater to our edge case.

An ideal solution would allow promises to bridge from Swift to Objective-C and back, but not lose the compelling features of each.

## Our Solution

PromiseKit 2.0 has two promise types:

 * `Promise<T>` (Swift)
 * `AnyPromise` (Objective-C)
 
Each is designed to be an approproate promise implementation for the strong points of its language:

* `Promise<T>` is strict, defined and precise.
* `AnyPromise` is loose, flexible and dynamic.

`AnyPromise` behaves like PromiseKit 1’s Objective-C promise implementation (`PMKPromise`):

```objc
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
```

The stringency of `Promise<T>`, however, requires you to specify the data type you expect by specializing your `then`:

```swift
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
```


# 2.0 Features

## Bridging Promises

If you have an `AnyPromise` you can use it in a `Promise<T>` chain:

```swift
someSwiftPromise().then { _ -> AnyPromise in
    // provided by `pod PromiseKit/SystemConfiguration`
    return SCNetworkReachability()
}.then { (obj: AnyObject?) in
    // AnyPromise always resolves with `AnyObject?`
}
```

Or you can directly then off it:

```swift
fetchKitten().then { (kitten: Kitten) in
    // this version is generic so you must specify the
    // type of the fulfillment value, above: `Kitten`
}
```

Objective-C can’t **see** instances of generic classes, so if we wanted to bridge a `Promise<T>` our only option is to write some Swift:

```swift
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
```

Please note, that it is essential that you `#import <PromiseKit/PromiseKit.h>` before you import the generated `YourProject-Swift.h` header in your Objective-C `.m` files. This is because of how we have declared our type `AnyPromise` to maintain backwards compatability. Sorry about this, but we have to balance many different convenience considerations.
    
## Cancellation

PromiseKit now supports the idea of cancellation.

If the underlying asynchronous task that the promise represents can be cancelled, then the author of that promise can register a specific error domain/code pair with PromiseKit. That error, then, will not trigger a catch handler. Here’s an example using an alert view:

```swift
let alert = UIAlertView(…)
alert.promise().then {
    // continue
}.catch {
    // this handler won’t execute if the user pressed cancel
}
```

This is typically what you want. If an alert is part of a chain and the user taps a button other than cancel, the chain will continue; however, if the user cancels, you want to abort the chain. But since the user explicitly cancelled the operation, you don’t want to run a catch handler that shows an error message.

You can opt-in to catch cancellation. Here’s a more elaborate example where cancellation is caught:

```swift
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
```

The PromiseKit categories have all been amended to handle cancellation for types that support it.

As an added bonus, you can now quickly cancel any chain:

```objc
[NSURLConnection GET:url].then(^{
    //…
}).then(^{
    @throw [NSError cancelledError];
}).then(^{
    //…
});
```

This can conveniently and elegantly replace rightward drift inside your chain, and you won’t need to remember to ignore some magical thrown-in value in your `catch` handlers.

## `recover`

To work around [ambiguity](https://github.com/mxcl/PromiseKit/issues/56) in `catch` we provide the alternatively named `recover` for `Promise<T>`:
    
```swift
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
```

With `AnyPromise`, `catch` itself (as before) can be used in this manner:

```objc
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
```

Note that `recover` always receives cancellations.


## `zalgo` and `waldo`

Promises always execute `then` handlers via <abbr title='Grand Central Dispatch'>GCD</abbr> (by default on the main queue). We provide `zalgo` and `waldo` for high performance situations where this slight delay must be avoided.

<center class="big" style="font-size: 1.1rem">
Please note, there are <a href="http://blog.izs.me/post/59142742143/designing-apis-for-asynchrony">excellent reasons</a> why you should never use <code>zalgo</code>. We provide it (mostly) for library authors who use promises. In such situations you should write tests to verify that you have not created possible race conditions.
</center>

Normally a `then` can be dispatched to the queue of your choice:

```swift
let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

NSURLConnection.GET(url).then(on: queue) {
    // we’re on the queue we asked for
}
```

Thus to zalgo we:

```swift
NSURLConnection.GET(url).then(on: zalgo) {
    // we will execute on the queue that the previous promise
    // resolved thus consider the queue completely *undefined*
}
```

Because the queue we execute on is undefined we provide `waldo`, which will unleash zalgo unless the queue is the main queue. In that case, we dispatch to the default background queue.

Again, **please** don’t use these in a misguided attempt to improve performance; the performance gain is negligible. We provide them for situations when it is imperative that there is minimal delay and for libraries that should be as performant as possible.


# Other Niceties

## `firstly`

Readability can be improved for simple chains if all promises are at the same level of indentation:

```swift
firstly {
    CLLocationManger.promise()
}.then {
    UIView.animate { foo.alpha = 1 }
}.then {
    NSURLConnection.POST(url)
}
```

Versus:

```swift
CLLocationManger.promise().then {
    UIView.animate { foo.alpha = 1 }
}.then {
    NSURLConnection.POST(url)
}
```


## 100% Test Coverage

PromiseKit 1.x was well tested, and includes a port of the entire Promises/A+ testsuite. PromiseKit 2.x has tests wherever possible, including testing categories that typically involve user interaction.


## Carthage Support

PromiseKit 1.x supports Carthage (though only for Swift), but you end up having all the categories compiled in and thus your application links against almost all system frameworks (which is rarely desired). PromiseKit 2’s xcodeproj only builds `CorePromise`. If you choose to use Carthage you will have to copy any categories into your sources in order to use them. Carthage will check out the category sources into `/Carthage/Checkouts/PromiseKit/Categories` for you.

CocoaPods, as ever, will compile categories into the framework itself, and since they are all subspecs, you can pick and choose which ones you get. By default, CocoaPods will only bundle the `Foundation` and `UIKit` categories.


# Caveats In Use

## `@import`

We worked hard to make a single framework that has a different public interface for Objective-C and Swift so you get the completion you need and not completion you don’t. The single caveat to this is that in `.m` files you must import with the old syntax:

```objc
#import <PromiseKit/PromiseKit.h>

// using @import will not break anything, but it will not
// import everything either:

@import PromiseKit;

// so if you must use it, use both:
@import PromiseKit;
#import <PromiseKit/PromiseKit.h>
```

With Swift, simply `import PromiseKit` as you would expect.

## Swift Compiler Issues

The Swift compiler will often error with `then`. To figure out the issue, first
try specifying the full signature for your closures:

```swift
foo.then { x in
    doh()
    return bar()
}

// will need to be written as:

foo.then { obj -> Promise<Type> in
    doh()
    return bar()
}

// Because the Swift compiler cannot infer closure types very
// well yet. We hope this will be fixed.

// Watch out for  one-line closures though! Swift will
// automatically infer the types, which may confuse you:

foo.then {
    return bar()  // 👌
}
```

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
* `AnyPromise` no longer catches most exceptions. Cocoa exceptions (almost entirely) represent serious programmer errors and should be allowed to crash the program. [Discussion here](https://github.com/mxcl/PromiseKit/issues/13). `Promise<T>` will not catch anything since you can’t throw nor can you catch anything in Swift. You can still `@throw` strings and `NSError` objects because we explicitly encouraged it as part of PromiseKit 1.x’s documentation and thus need to continue supporting it.
* `PMKJoin` has a different parameter order per the documentation.
* PromiseKit 2.0 has an iOS 7 minimum deployment target, though for users who want convenience, it is 8.0. This is because CocoaPods and Carthage will only build Swift projects for iOS 8. For iOS 7 we provide an [iOS 7 EZ-Bake](https://github.com/PromiseKit/EZiOS7) that makes it much easier to use PromiseKit 2 in iOS 7 targets. For iOS 6 and below you can still use PromiseKit 1.x. Most of the benefits of PromiseKit 2 are the cross-language bridging of promises.
* PromiseKit 2 is mostly written in Swift. This means you will have to check the relevant project settings to embed a Swift framework.
* `promiseViewController` with a `UIImagePickerController` no longer provides the original media data for its second parameter. Sorry but to do this imposed AssetsLibrary linkage on all PromiseKit consumers. The Swift categories still provide this option, since with Swift we can discern what you want precisely, so it can be provided in a separate file as a separate subspec. If you depended on this feature you can still get the original data, just grab the code from PromiseKit 1.x’s sources.

In a few months we will delete the Swift portion of PromiseKit 1.x (CocoaPods will still find it if you depend on PromiseKit 1.x). It was never officially endorsed, and 2.x is better in every way.

**If when porting from 1 to 2 you believe something no longer works, but it *should*, please, open a ticket. We believe in as much source compatability between major releases as possible**.

Porting should be straight forward, but please be aware of the above, especially for any promises with changed then signatures for Objective-C promises (the only signatures that were intentially changed were `join` and promiseViewController for `UIImagePickerController`, so if you find a signature that is different otherwise, it is a bug, please report it).

Cancellation *should* work for you as before, but it depends on how you were handling the cancellation in your codebase, so be careful.

When in doubt, don’t upgrade major versions of third party libraries for production applications! We tried very hard to respect your commitment to PromiseKit, but it is not worth the risk unless you do thorough Q&A.


# The Future

PromiseKit is under active development and is used in hundreds of apps on the store. We will continue to improve and maintain it with your continued support!

[PromiseKit on Github](https://github.com/mxcl/PromiseKit)