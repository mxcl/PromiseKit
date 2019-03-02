---
layout: default
title: PromiseKit 6.0 Released
---

# PromiseKit 6 Released

I know what you’re thinking, PromiseKit 6, whatever happened to PromiseKit 5?

Well PromiseKit 6 is almost identical to 5, but it had a minor, but breaking
change and we respect semantic versioning.

Anyway, we’ll talk about that soon.

## Notable Changes Since PromiseKit 4

### `Guarantee<T>`

Some asynchronous tasks cannot error, to represent this we now have `Guarantee`.

Rather than return a `Promise`, if an asynchronous task cannot error it returns
a `Guarantee`:

```swift
after(seconds: 0.3).then {
    // triggers after 0.3 seconds, and of course, this cannot error
}

// ^^ There is no `catch`; you *cannot* write one. Errors are not possible.
```

The key difference is the lack of the need for a `catch`, and in addition, we
use Swift to inform you of this, `Promise`’s `then` does not declare
`@discardableResult`, so you get a warning to *do something* with the result of
your `then`, that is, you must `catch` or return the promise thus punting the
warning to a higher level, where you there will need to `catch`:

```swift
fetch().then {
    //…
}

// ^^ Swift will warn “unused result” which is your hint that you forgot error handling
// NOTE `fetch` returns Promise, you’d get *no warning* if it returned Guarantee

fetch().then {
    //…
}.catch {
    //…
}

// ^^ no warning

return fetch().then {
    //…
}

// ^^ warning is punted to the caller of this function,
// ie. caller takes responsibilty for error handling
```

`Guarantee`s make using PromiseKit as error-safe as Swift, thus they match the
Swift error system's intent and since Promises are like `do`, `try`, `catch`
blocks but for asynchronicity: this works well.

Another marvelous outcome of this is our `when(resolved:)` variant. This `when`
always resolves because it resolves with an array of `Result`, thus it *cannot*
error. With PMK4 you had to just know that you didn't need to `catch` with
PMK 6 Swift itself knows you cannot `catch` because it returns a `Guarantee`.

```swift
when(resolved: promises).done { results in
    //…
}

// ^^ There is no `catch`; you *cannot* write one. Errors are not possible.
```

> *Note* we also provide `when(fulfilled:)` which rejects if any of the promises
it is waiting on `reject`. Generally this is the version you *should* use but
when you need all promises to finish even if they error you can use the above
`when(resolved:)` variant and the language itself will make it clear that there
can be no error handling!

> *Note* sometimes you just don’t care about the `catch` (you monster you!),
so we provide `cauterize()` use it to terminate a chain, log any error and
remove the warning from your `Promise` chain.

### `Thenable`

Guarantees and Promises both conform to the same protocol `Thenable` and thus
can be combined. If you return a Promise from a `Guarantee`’s `then` (or if you
throw) the chain becomes a Promise chain. If you use `recover` on a `Promise`
chain it becomes a `Guarantee`.

In use we find the introduction of `Guarantee` fabulous and very “Swifty”.

> Notably returning a `Guarantee` from a `Promise`’s `then` does not cause that
`then` to return a `Guarantee`. Any part of a previous chain could have error’d
even if that specific `then` does not, so we cannot become a `Guarantee` unless
you `recover` (and in order to remain a `Guarantee` your recover handler cannot
`throw`!) first.

## Why PromiseKit 5/6?

For the first year running we didn't need a new major version for Swift 4. Swift
3 and 4 had very few breaking language or stdlib changes. Thus PromiseKit 4 & 6
both support Swift 3 & 4.

Using PromiseKit has been delightful… and awful. Swift is great… and terrible,
specifically its error diagnostics are so bad in certain conditions that I
honestly have started to wonder if recommending the language is still a good
idea. Like, Javascript is terrible, but at least when it goes wrong you can
figure out what you have to do to fix your code. Swift lies.

If there is an error inside a closure, Swift, with no improvements since v1 :(,
has told you the wrong error.

PromiseKit is all closures. So you can see our problem.

I believe in tools that are as easy to get up to speed with as possible, the
idea that you should have to spend time learning how to use something so that
you can get your work done quicker is nonsense. You should reject that. We do.

With PromiseKit our `then` did multiple things, and we relied on Swift to infer
the correct `then` from context. However with multiple line `then`s it would
fail to do this, and instead of telling you that the situation was ambiguous it
would invent some other error. Often the dreaded
`cannot convert T to AnyPromise`. We have a troubleshooting guide to combat this
but I believe in tools that just work, and when you spend 4 years waiting for
Swift to fix the issue and Swift doesn't fix the issue, what do you do? We chose
to find a solution at the higher level.

So we split `then` into `then`, `done` and `map`.

* `then` is fed the previous promise value and requires you return a promise.
* `done` is fed the previous promise value and returns a `Void` promise (which is 80% of chain usage)
* `map` is fed the previous promise value and requires you return a non-promise, ie. a *value*.

At first I was nervous about this. But with some use on real projects I quickly
realized that `done` alone was making PromiseKit use much more pleasant. Because
Swift has no inference to do about the return for `done` you can write many line
closures without any pain. `then` and `map` still require you to specify the
return types for closures if they are multiple line, but often they are single
line because you are chaining promises encapsulated in other functions.

The result is a happier compiler, a happier *you* and also, pleasantly (and
somewhat surprisingly), clearer intent for your chains.

### `compactMap`

Having added `map` desire for other functional primitives began. So we tried
`compactMap`. Probably the most useful new introduction. So many Swift methods
return an optional (`if let` is a great language feature after all), in a
promise chain you need to functionally transform values, and `compactMap` lets
you get error transmission when `nil` is returned, for example:

```swift
firstly {
    URLSession.shared.dataTask(.promise, with: url)
}.compactMap {
    String(data: $0.data, encoding: .utf8)  // returns `String?`
}.done {
    //…
}.catch {
    // though probably you should return without the `catch`
}
```

See the composability section later, but `compactMap` alone allowed us to reduce
the magic of PromiseKit and make it more immediately understandable. Previously
our `URLSession` promises were more black-boxed returning a magic object that
made their use sometimes tedious for the sake of adding methods like `asImage()`
to facilitate their use in chains. Now if you need an image from a dataTask you
can compose it:

```swift
firstly {
    URLSession.shared.dataTask(.promise, with: url)
}.compactMap { data, urlResponse in
    UIImage(data: data)
}.done {
    //…
}
```

> Note we released `compactMap` as `flatMap`, [see discussion here](https://github.com/mxcl/PromiseKit/issues/773).

### `get`

`get` is `done` but it returns the same value that your handler is fed:

```swift
firstly {
    .value(1)
}.get { foo in
    print(foo, " is 1")
}.done { foo in
    print(foo, " is 1")    
}
```

This is also a common pattern, hence once we had started supplementing your
toolkit we added this also.

### `tap`

An insertion for chain debug:

```swift
firstly {
    .value(1)
}.tap { result in
    print(foo, " is Result.fulfilled(1)")
}.done { foo in
    print(foo, " is 1")
}
```

`tap` feeds you the current `Result<T>` for the chain, so is called if the
chain is succeeding or if it is failing.

### `lastValue`, `firstValue`, `filterValues`, `compactMap`, etc.

We have added many of the other functional primitives that `Sequence` have
including logical extensions like `thenMap`.

```swift
firstly {
    return when(fulfilled: promisesForDataFetches)
}.map {
    String(data: $0)  // runs for each data from the `when`
}.thenMap {
    fetch(stringUrl: $0) // fetch returns promise, runs once for each string
}.done { arrayOfFetchedThings in
    // finally you have an array of things!
}
```

[Naming discussion was here](https://github.com/mxcl/PromiseKit/issues/773).

## `Promise.init`

We altered the main initializer:

```swift
Promise { fulfill, reject in
    //…
}
```

You now have:

```swift
Promise { seal in
    // seal.fulfill(foo)
    // seal.reject(error)
    // seal.resolve(foo, error)
}
```

We considered adding a new initializer that provided the `seal` object, but this
led to the usual Swift ambiguity issues despite the different parameter counts.

So sadly, in order to progress we have had to change a fundamental.

However there are good reasons for it. The `seal` has many overrides of
`resolve` so you can typically just pass `seal.resolve` to a completion handler
and Swift will automatically figure out the types:

```swift
func myFunction(withCompletion: (String?, Error?) -> Void) {
    //…
}

Promise {
    myFunction(withCompletion: $0.resolve)
}.then { foo in
    // foo is `String`!
}.catch {
    // errors from myFunction are handled!
}
```

We also provide specific variants of the `Sealant` object for `Void` and `Bool`
completions.

## Extensions Changes

### Composability

We have attempted to make all the extensions more useful and more composable.

For example `CLLocationManager.promise()` used to return `LocationPromise` which
inherited `Promise<CLLocation>` and had a function on it that returned
`Promise<[CLLocation]>` so that you could get all the locations that may have
been returned during the `CLLocationManager`’s updateLocation period.

Now we return `Promise<[CLLocation]>` so there is no new class to look at or
understand. Instead we provide a `.last` (or `.first`) method. Which you should
use:

```swift
firstly {
    CLLocationManager.requestLocation()
}.last.done { location in
    //…
}
```

If the array is empty PromiseKit fails the chain (say hi in your `catch`).
Otherwise you get one result.

### Ambiguity`--`

For some of our extensions we made using Apple's frameworks less good. Ambiguity
resulted. For example:

```swift
let promise = URLSession.shared.dataTask(with: url)
```

Swift cannot infer the type of `promise` because PromiseKit and Foundation both
provide versions of this method (Foundation’s returns `URLDataTask`).

Usually you didn’t have problems because when returning into chains Swift could
figure out which you wanted. Nonetheless we have fixed this, now you do:

```swift
let promise = URLSession.shared.dataTask(.promise, with: url)
```

Swifty, readable, clear and the compiler is happy.

### Naming

In general we have tried to improve naming and align as closely as possible to
the Apple functions we mirror. For example:

```swift
CLLocationManager.promise() -> CLLocationManager.requestLocation()

UIView.promiseAnimation(withDuration: 0.3) -> UIView.animate(.promise, duration: 0.3)

DispatchQueue.global().promise -> DispatchQueue.global().async(.promise)
```

## What Happened to PromiseKit 5?

We released 5 to Carthage, but weren’t entirely confident in it. In the end this
proved right, we didn't remove all ambiguity. This constructor was evil:

```swift
Promise(value: T)
```

Swift is greedy and would try to use this constructor too readily. For example:

```swift
let p = Promise { fulfill, reject in
    fulfill(1)
}
```

What should `p` be? Hopefully `Promise<Int>` but actually, sometimes,
`Promise<(_->Void, (Error)->Void)>`. Yeah. What the…? Well it's because
of trailing closure syntax, and Swift greedily trying to use this initializer
even though there is the much better `Promise(resolver:)` intializer that
fits this syntax exactly.

When this happened you’d almost always spot it, however we had situations where
it got to production due to Swift type inference hiding the mis-identification
of the type from us.

So we removed it. So now if you need a resolved promise use:

```swift
return .value(1)
```

Which is a static method on `Promise<T>`.


## Defining the Default DispatchQueue 

By default all PromiseKit handlers dispatch to `.main`, this is safest and thus
the default.

However we heartily recommend you change the default queue for `then`, `map` and
the other “transforming” functions to a background queue.

PromiseKit has always allowed you to change the default queue, but 6 goes a 
little further and distinguishes between the two main kinds of handler: those
that transform values and usually are stateless, and those that finalize chains
and usually modify application state. It's the latter that you almost always
want on the main queue since it acts as an easy form of synchronization:

```swift
PromiseKit.conf.Q.map = .global()
PromiseKit.conf.Q.return = .main  // FYI this is the default
```

Especially now Xcode 9 gives a runtime warning for using function that must be
on the main queue in the background. This is a low-risk, high-gain tweak for
your apps.

> Note sorry about these names. I missed the `TODO` to fix them before release…


## Defining the Default Catch Policy

You can now define that the default catch policy for all `recover` and `catch`
by `allErrors` rather than `allErrorsExceptCanncellation` by changing
`conf.catchPolicy`.

> To learn more about PromiseKit’s cancellation system, see the dedicated part
of our documentation at GitHub.
  
## Migration Guide

### Initializers

```swift
Promise { fulfill, reject in
    asyncThing { value, error in
        if let value = value {
            fulfill(value)
        } else if let error = error {
            reject(error)
        } else {
            reject(PMKError.invalidCallingConvention)
        }
    }
}
```

Becomes:

```swift
Promise { seal in
    asyncThing { value, error in
        seal.resolve(value, error)
    }
}
```

You can even go this far for completion-handler only systems:

```
Promise(resolver: asyncThing)
```

### `Promise(value:)`

We removed this initializer (rationale is above), so:

```swift
return Promise(value: foo)
```

Becomes:

```swift
return .value(foo)
```

### `then`

You may need to convert your `then`s into `done` or `map`. Explore `compactMap`
also since it can really help you to write quick chains that behave exactly as
you want.

### Look for opportunities to use `Guarantee`

If your chain cannot fail try to use Guarantees. One way to force a guarantee
is to use `recover` to recover all errors:

```swift
foo().recover{_ in}.done { foo in
    //…
}
```

Use this carefully! Ideally you’d just convert `foo()` to return a `Guarantee`,
aim for the lowest level where there are no errors and switch that over.

### `wrap`

`wrap` is no longer provided, use `Promise(resolver:)`:


```swift
return PromiseKit.wrap(start)
```

Becomes:

```swift
return Promise { start(completionHandler: $0.resolve) }
```

It was always desired to have `wrap` be a `Promise` initializer for clarity
reasons, but it wasn't possible until Swift 3.1 allowed us to specialize
extensions. So now we can do it, we do.

### `always`

`always` is now `ensure`.

### `Promisable`

Previously we provided a `Promisable` protocol as part of our UIKit extensions
to facilitate using promises with `UIViewController` presentation and
dismissals.

I'm sorry if you depended on this because we have removed it. We feel it was
not a good *general* solution and we feel it was a bad pattern that violated
the encapsulation of your view-controller heirarchy.


Instead we suggest adding some minimal code to your view controllers that you
want to be governed by a promise. To be clear this still violates encapsulation
because the viewController dismisses itself, but that's your decision to make
(I do it in my apps!), it’s just that the library itself should not promote this
pattern.

```swift
class ViewController: UIViewController {

    private let (promise, seal) = Promise<…>.pending()  // use Guarantee if your flow can’t fail
    
    func show(in: UIViewController) -> Promise<…> {
        in.show(self, sender: in)
        return promise
    }
    
    // you will need to call this instead of `dismiss`
    // if there's a sure-fire way to know when a vc is dismissed, Apple don't document it.
    func done() {
        dismiss(animated: true)
        seal.fulfill(…)
    }
}
```

### `PMKAlertController`

Removed. This was not good enough a model for the library, by all means grab it
from PMK4 and use it, but we should not encourage this generally. Instead you
can easily add promises yourself:

```swift
Promise { seal in
    let ac = UIAlertController(…)
    ac.addAction(.init(…, completionHandler: seal.fulfill))
    ac.addAction(.init(…, completionHandler: seal.reject))
    present(ac, animated: true)
}.done { _ in
    //…
}.catch { _ in
    //…
}
``` 

Doing it yourself gives you control over what fulfilled and rejected mean in
your own contexts. Or just use a Guarantee if there is no error condition.

### Zalgo

If you must unleash zalgo, we now accept `nil` as the queue for any handler,
which aligns us more closely with what `nil` (usually) means with Apple's
APIs for queue type parameters.


### `then(execute:)`

Because it reads better we dropped the `execute:` parameter name for `then`, so:

```swift
fetch().then(execute: layout)
```

Becomes:

```swift
fetch().then(layout)
```

Of course this only applies when you pass functions directly to `then`.


### `.catch{ /*…*/ }.finally`

In PMK 4 `catch` returned the promise it was attached to. This led to unexpected
behavior for many people and was a mistake. Sorry.

However, often it is useful to have what is an `ensure` and to have it occur
after your `catch` handler. Thus we have `finally` (named because it really is
*finally*).

```swift

spinner(visible: true)

firstly {
    foo()
}.done {
    //…
}.catch {
    //…
}.finally {
    self.spinner(visible: false)
}
```

> Note, indeed you cannot do anything else after a `catch`. `catch` is a chain-
terminator, if we allowed you to generally chain off of it it would easily lead
to situations of ambiguity for *you*, what should happen if you `catch` after a
`catch`? What is the value of the chain after the `catch`? These are questions
that could have multiple answers.

If you want the previous behavior, either use `recover` or do what the previous
`catch` did, ie. return the promise:

```swift
let p = somePromise()
//…
p.catch { /**/ }
return p
```

### No More Unhandled-Error-Handler

Relunctantly this is gone. A fabulous feature, but maintaining it was quite a
burden. Partly the reason we justify this is now it is quite hard to *not*
handle errors due to `Guarantee` and Swift warning when you don’t add `catch`
to your chains. Still there are scenarios that you can concoct where by you
could have chains without error-handling. Ideally we would bring this back, but
it is immensely intrusive to our codebase. PR welcome.

### ObjC API for AnyPromise no longer supports cancellation

The bridging between Error and NSError and supporting cancelation on top of this
was tricky. In the end rather than try to anticipate every possibility we
removed this feature.

> NOTE The Swift interface for AnyPromise *still* supports cancellation.

To work around this you can make your own `@objc` Swift extension for `NSError`
that can inform you about cancellations you are interested in.

`NSError.cancelledError` thus has been removed, you can use `PMKError.cancelled`
instead now.


### Apologies, there are a lack of deprecations

We do not have many deprecations, so your code may stop compiling if you
upgrade. The reason for the lack of deprecation notices is again: ambiguity.
Swift tends to pick even deprecated versions of ambiguous functions, and this
led to pain when writing new code.

We suggest looking at the [sources for the extensions](https://github.com/PromiseKit)
we provide should you need to. The code is neatly organized and easy to read.

## Wishlist for Swift 5

Swift still sucks for error diagnostics, and it is a massive barrier to entry
for newcomers to programming (I teach newcomers to programming at my coding
school).

For example PromiseKit still sucks because of Swift errors, here's an example:

```swift
try service.fetchAll().then { result in
      self.projects = result.projects
}
```

This errors. The issue is: `then` requires you to return a `Promise` and nothing
is returning. So what error does Swift give us?

    error: Type of expression is ambiguous without more context

While error messages are basically useless as much as half the time Swift will
lose mind-share and respect. I see it with new devs, they shake their heads and
then tell me they prefer Javascript, they then start reading up about React
Native.

I even see experienced developers not know how to proceed here, and this is for
the additional reason that getting Xcode to show you the function definition for
Swift code is a toss-up, half the time it doesn’t work, so experienced devs have
stopped trying to make it work. When you can’t trust your tools you can’t get
things done.

## PromiseKit is now in maintenance mode

We really don't expect any further large changes. We believe we have correctly
applied promises to Swift and that Swift itself won't change that much in the
future.
  
## Feedback

Welcome! [Open a ticket](https://github.com/mxcl/PromiseKit/issues/new).
