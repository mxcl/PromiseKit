---
layout: default
title: FAQ
nav: FAQ
order: 3
redirect_from:
 - "/dispatch-queues/"
 - "/getting-started/"
 - "/cocoapods/"
 - "/troubleshooting/"
 - "/common-misusage/"
 - "/appendix/"
 - "/glossary/"
---

## Why won’t my `then` compile?

You’re seeing errors like:

> Cannot convert return expression of type `…` to return type `AnyPromise`

Or:

> Missing return in a closure expected to return `AnyPromise`

In Swift simple closures are inferred, so this works fine:

```swift
authPromise().then {
    return locationPromise()
}.then {
    print("done")
}
```

However this will error:

```swift
authPromise().then {
    let promise = locationPromise()
    return promise
}.then {
    print("done")
}
```

To fix it specify the return type:

```swift
authPromise().then { authResult -> Promise<CLLocation> in
    let promise = locationPromise()
    return promise
}.then {
    print("done")
}
```

Swift will claim you should return `AnyPromise` but this is a compiler error bug, it should
say “*Unable to infer return type `T' for closure*”, the bug is because the Promise is a generic
class and the generic type is part of the signature for all `then` functions.

We attempted many hours to improve this situation since it is by far the most common issue
people run into, Swift usually does not require you to specify the return type for closures
that have a non-generic return type. Unfortunately this situation could not be improved by
any modification to the `then` signature we could think up.

## How do I install and make use of PromiseKit?

The easiest option is to use the [CocoaPods app](https://cocoapods.org/app) and then add this to your `Podfile`:

```ruby
pod "PromiseKit", "~> 3.5"  #Xcode 7
pod "PromiseKit", branch: "swift-3.0"  # Xcode 8
```

For other options, see our comprehensive [README](https://github.com/mxcl/PromiseKit/blob/master/README.markdown).

## Can I use PromiseKit with Objective-C as well as Swift?

PromiseKit has two promise classes:

* `Promise<T>` (Swift)
* `AnyPromise` (Objective-C)

Each is designed to be an approproate promise implementation for the strong points of its language:

* `Promise<T>` is strict, defined and precise.
* `AnyPromise` is loose, flexible and dynamic.

Unlike most libraries we have extensive bridging support, you can use PromiseKit in mixed projects with mixed language targets and mixed language libraries.

## Which PromiseKit Should I Use?

If you are writing a library, use [PromiseKit 1.x](https://github.com/mxcl/PromiseKit/tree/legacy-1.x). PromiseKit is built on Swift and thus breaks at least once a year. While Swift is in flux it is not feasible to depend on a library that will break every time Xcode updates.

If you are making an app then version 4 is the best PromiseKit, you may have to make some fixes when Xcode updates, but probably you will be OK as long as you update PromiseKit when Xcode updates.

PromiseKit 1 and 4 can be installed in parallel if necessary, but CocoaPods will not support this.

Once Swift becomes ABI or API stable we can all just move to the latest PromiseKit.

Thus we intend to support PromiseKit 1.x for longer than expected.


## How can I control the thread/queue upon which handlers execute?

The function signature of `then` is:

```swift
func then<U>(on: DispatchQueue = PMKDefaultDispatchQueue(), execute: (T) throws -> U) -> Promise<U>
```

Your promises have been specifying their queue all along, it was just a hidden default parameter. `catch`, `recover` and `always` also have an `on:` parameter.


## Why does PromiseKit always `dispatch_async`?

[http://blog.izs.me/post/59142742143/designing-apis-for-asynchrony]()


## Debugging is hard

Due to promise chaining errors can end up quite far from where they were thrown.

The best way thus to aid debugging is to throw **really good** errors.

Sadly Cocoa doesn’t throw good errors.

Assuming no other APIs you are wrapping do asynchronicity you can sometimes create a stack trace that helps lead back to the throw site by using `zalgo`:

```swift
PMKSetDefaultDispatchQueue(zalgo)
```

Call this function as early in your app as possible.

**Only do this while debugging!**

Note that if the APIs that PromiseKit wraps are asynchronous then chances are your backtrace situation will not improve. The problem is asynchronous systems, not PromiseKit itself.


## How can I `return` multiple values from my `then`?

Simply return a tuple:

```swift
foo.then {
    return (1, 2)
}.then { a, b in
    print(a, b)
}
```


## Should I be concerned about retain cycles?

tl;dr: it’s safe to use self in promise handlers.

This is safe:

```swift
somePromise.then {
    self.doSomething()
}
```

Provided `somePromise` resolves, the function passed to `then` will be released, thus specifying `[weak self]` is not necessary.

Specifying `[unowned self]` is likely dangerous.


## You’re telling me not to worry about retain cycles?!

No, it’s just that by default you are not going to cause retain cycles when using PromiseKit. But it is still possible, for example:

```swift
self.handler = {
    self.doSomething
    self.doSomethingElse
}

somePromise.then(execute: self.handler)
```

The closure we assign to `handler` strongly retains `self`. `handler` is strongly retained by `self`. It’s a typical retain cycle. Don’t write typical retain cycles!

Notably, this is not a retain cycle:

```swift
somePromise.then(execute: self.doSomething).then(execute: self.doSomethingElse)
```

## Why is my Objective-C `catch` continuing my chain?

Watch out for `catch` in Objective-C, it returns `AnyPromise` which means in the following example the `then` block **always** executes:

```objc
self.somePromise.catch(^(NSError *err){
    [UIAlertView show:err];
}).then(^(id o){
    // this block always executes!
    assert(o == nil);
})
```

The Objective-C `catch` behaves like typical Promises in other dynamic languages: it behaves like Swift’s `Promise<T>` `recover`. If you want to continue a chain from a `catch` in Objective-C be careful and ensure you **rethrow** the error if you want it to continue rejected or return a new value to continue it fulfilled or return nothing to have it continue as a `void` promise.


## Why am I getting `EXC_BAD_ACCESS`?

Something got deallocated, and you still used it as part of your promise chain.

When wrapping delegate patterns, the delegate property is usually `assign` which means if nothing else points to it, it will be deallocated immediately. The block-heavy nature of promises can easily lead to this situation, so it is something to be aware of.

See the code in our `Categories` directory for examples of how to avoid crashes with delegate patterns.


## Why do I get so many errors writing Swift promises?

Swift compile errors are still a little flakey:

1. Ensure that your code in your closure actually compiles by extracting it out of the closure.
2. Try setting the parameter and return type of your handlers.


## Why don’t my chains work?

Promises only chain if you **return** the promise, for example:

```objc
foo.then(^{
    [self promise];
}).then(^{
    NSLog(@"Happens immediately! WTF?!");
});
```

See the issue? We don’t `return [self promise];` thus this promise is not actually part of the chain.


## Why is my promise code so nested?

Do you have code like this?

```swift
func toggleNetworkSpinnerWithPromise<T>(funcToCall: () -> Promise<T>) -> Promise<T> {
    return Promise { fulfill, reject in
        firstly {
            setNetworkActivityIndicatorVisible(true)
            return funcToCall()
        }.then { result in
            fulfill(result)
        }.always {
            setNetworkActivityIndicatorVisible(false)
        }.error { err in
            reject(err)
        }
    }
}
```

Instead write this:

```swift
func toggleNetworkSpinnerWithPromise<T>(funcToCall: () -> Promise<T>) -> Promise<T> {
    return firstly {
        setNetworkActivityIndicatorVisible(true)
        return funcToCall()
    }.always {
        setNetworkActivityIndicatorVisible(false)
    }
}
```

You already had a promise, don’t wrap it in another promise, instead chain it!


## Is PromiseKit thread-safe?

Yes, all methods and properties on promises are thread-safe, however the code you write in your handlers will need to b thread-safe itself.

The easiest way to ensure this is to only call `then` without specifying a queue, then all access to a promise’s values will occur serially on the main queue.

Provided you are writing an app and not a library, and provided you typically only add one `then` per promise, and provided you typically run all thens on the main queue, you won't have anything to worry about.

So for most users everything is intrinsically safe.


## Why are there separate classes for Objective-C and Swift?

Objective-C can not bridge objects from Swift that are generic. Generic promises allow you Swift promise code to be strict and powerful. It would be a pity to either have untyped promises in Swift or no promises in Objective-C which are the other two options.


## Does PromiseKit conform to Promises/A+?

Yes. We have full tests that demonstrate our conformity.


## What alternatives exist to PromiseKit?

Promises/Futures are not our invention, so take your pick:

* [BrightFutures](https://github.com/Thomvis/BrightFutures) a good one.
* [Bolts](https://github.com/BoltsFramework/Bolts-iOS) 
  * More or less a promises implementation.
  * The syntax is not as nice. Your “thens” must always take a single (just one!) argument and always return an object (even if you have nothing to return, you must return `nil`). It is our opinion that this additional clutter reduces the clarity of your code.
  * You don’t get any categories to help you use Apple’s APIs out the box.
  * But, it’s built into Parse, so if you’re using that you’re already set.
  * More flexible at a lower level than PromiseKit (eg. you can define your own execution queues)
  * Not modular. The framework itself even comes with a completely unrelated URL parsing library.
* [Reactive Cocoa](https://github.com/ReactiveCocoa/ReactiveCocoa) Reactive Cocoa is amazing, but requires a large shift in the way you program. PromiseKit is a happier compromise between the way most people program for iOS and a pure reactive paradigm. However, reactive programming is probably the future of our art.

If you desire something more *bare-bones* there are numerous github projects with the word “task” or “promise” in the title that you may prefer.

PromiseKit is well-tested, and inside hundreds of apps on the store. It also is fully documented, even within Xcode (⌥ click any method).


## How can I pass through values from a previous handler?

```swift
foo().then { bar in
    return goo().then{ (bar, $0) }
}.then { bar, baz in
    //…
}
```

This is often an indication of a bad pattern however, you may be better off nesting the handlers:

```swift
foo().then { bar in
    return goo().then{ goo in
        // can use goo and bar
    }
}
```


## Why can’t I `when` more than three promises?

We provide convenience `when`s in Swift that map different `Promise<T>`, however we only provide this up to three parameters. If you need to `when` more than three promises you must `when` promises of the *same generic type*, for example all `Promise<Int>`.

This can be difficult, but one trick is to make them `Void` and then get the values out after:

```swift
when(a.asVoid(), b.asVoid(), c.asVoid(), d.asVoid()).then { _ -> Void in
    let a = a.value
    let b = b.value
    let c = c.value
    let d = d.value
}
```

We agree this is tedious, but other than specializing `when` for more parameter counts there is nothing we can do with current Swift versions.


## What is the difference between PromiseKit and RxSwift?

[https://github.com/mxcl/PromiseKit/issues/484](https://github.com/mxcl/PromiseKit/issues/484)


## How can I wait on a promise?

[https://github.com/yannickl/AwaitKit](https://github.com/yannickl/AwaitKit)

## Why can’t I return from a `catch` like I can in Javascript?

Swift demands functions with one purpose, thus we have two error handlers:

* `catch`, end promsie chain and handle error
* `recover`, attempt to recover from errors in a chain

You want `recover`.

## My question was not answered

[Please open a ticket](https://github.com/mxcl/PromiseKit/issues/new).
