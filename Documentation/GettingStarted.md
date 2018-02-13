# `then` & `done`

Here is a typical promise chain:

```swift
firstly {
    login()
}.then { creds in
    fetch(avatar: creds.user)
}.done { image in
    self.imageView = image
}
```

If this code used completion handlers it would look like this:

```swift
login { creds, error in
    if let creds = creds {
        fetch(avatar: creds.user) { image, error in
            if let image = image else {
                self.imageView = image
            }
        }
    }
}
```

`then` *is* just another way to do completion handlers, but it is also quite a
bit more. At this initial stage of our understanding it merely helps
readability. The promise chain above is easy to read, one asynchronous operation
leads into the other, read line by line. It's as close to
procedural code as we can easily get with the current state of Swift.

`done` is the same as `then` but you cannot return a promise, it is the
typically the end of the “success” part of the chain. Above you can see how we
get the final image in our `done` and use if to set our UI.

Let’s compare the signatures of the two login methods:

```swift
func login() -> Promise<Creds>
    
// compared with:

func login(completion: (Creds?, Error?) -> Void)
                        // ^^ ugh. Optionals. Double optionals.
```

The distinction is that with promises your functions returns *promises*. So for each handler in our
chain we return a promise. By doing this we can call `then`. Each `then` waits on its promise, so the
chains resolve procedurally, one at a time.

A `Promise` represents the future value of an asynchronous task. It has a type
that represents the type of object it wraps. In the above example `login` is a
function that returns a `Promise` that *will* represent an instance of `Creds`.

> Note, `done` is new to PromiseKit 5, previously we had a `then` variant that
did not require a promise to be returned. The problem is, this often confused
Swift leading to confusing and hard to debug error diagnostics, but also it made
using PromiseKit more painful; introducing `done` makes it possible to type out
promise chains that compile without additional qualification to help the
compiler.

---

You may notice that unlike the completion pattern, the promise chain appear to
ignore errors, this is not the case, instead it is the opposite: the promise
chain makes error handling more accessible and harder to ignore.


# `catch`

With promises, errors cascade ensuring your apps are robust and the code,
clearer:

```swift
firstly {
    login()
}.then { creds in
    fetch(avatar: creds.user)
}.done { image in
    self.imageView = image
}.catch {
    // any errors in the whole chain land here
}
```

> In fact, Swift emits a warning if you forget to `catch` a chain. But we'll
> talk about that more later.

Promises each are objects that represent individual asychnronous tasks. If those
tasks fail their promises become *rejected*. Chains that contain rejected
promises skip all subsequent `then`s, instead the next `catch` is executed
(strictly, *any* subsequent `catch` handlers).

For fun let’s compare this pattern with a completion handler equivalent:

```swift
func handle(error: Error) {
    //…
}

login { creds, error in
    guard let creds = creds else { return handle(error: error!) }
    fetch(avatar: creds.user) { image, error in
        guard let image = image else { return handle(error: error!) }
        self.imageView.image = image
    }
}
```

Use of `guard` and a consolidated error handler help, but the promise chain’s
readability speaks for itself.


# `ensure`

We have learned to compose asynchronicity. Next let’s extend our primitives:

```swift
firstly {
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
    return login()
}.then {
    fetch(avatar: $0.user)
}.done {
    self.imageView = $0
}.ensure {
    UIApplication.shared.isNetworkActivityIndicatorVisible = false
}.catch {
    //…
}
```

Whatever the outcome in your chain—failure or success—your `ensure`
handler is called.

For fun let’s compare this pattern with a completion handler equivalent:

```swift
UIApplication.shared.isNetworkActivityIndicatorVisible = true

func handle(error: Error) {
    UIApplication.shared.isNetworkActivityIndicatorVisible = false
    //…
}

login { creds, error in
    guard let creds = creds else { return handle(error: error!) }
    fetch(avatar: creds.user) { image, error in
        guard let image = image else { return handle(error: error!) }
        self.imageView.image = image
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}
```

Here it would be trivial for somebody to amend this code and not unset the activity indicator leading to a bug. With
promises this is almost impossible, the Swift compiler will resist you supplementing the chain without promises, you
almost won’t need to review the pull-requests.

> Note PromiseKit has inconveniently switched between naming this function
`always` and `ensure` multiple times. Sorry about this, we suck.


# `when`

With completion handlers reacting to multiple asycnhronous operations is either
slow or hard. Slow means doing it serially:

```swift
operation1 { result1 in
    operation2 { result2 in
        finish(result1, result2)
    }
}
```

The fast (*parallel*) path code makes the code less clear:

```swift
var result1: …!
var result2: …!
let group = DispatchGroup()
group.enter()
group.enter()
operation1 {
    result1 = $0
    group.leave()
}
operation2 {
    result2 = $0
    group.leave()
}
group.completion = {
    finish(result1, result2)
}
```

Promises are easier:

```swift
firstly {
    when(fulfilled: operation1(), operation2())
}.done { result1, result2 in
    //…
}
```

`when` takes promises, waits for them to resolve and returns a promise with the results.

And of course, if any of them fail the chain calls the next `catch`, like *any* promise chain.


# PromiseKit Extensions

When we made PromiseKit we understood that we wanted to *only* use promises, thus, wherever possible, we offer
extensions on top of Apple’s APIs that add promises. For example:

```swift
firstly {
    CLLocationManager.promise()
}.then { location in
    CLGeocoder.reverseGeocode(location)
}.done { placemarks in
    self.placemark.text = "\(placemarks.first)"
}
```

To use these you need to specify subspecs:

```ruby
pod "PromiseKit"
pod "PromiseKit/CoreLocation"
pod "PromiseKit/MapKit"
```

All our extensions are available at the [PromiseKit organization](https://github.com/PromiseKit) and you should go there
to see what is available and to read the sources so that you can read the documentation. We have copiously documented every
file and every function.


# Making Promises

You can get a long way with our extensions, but sometimes you have to start chains of your own. Maybe you have a third party
API that doesn’t provide promises, or maybe you wrote your own asynchronous system. Either way, we provide the starting point,
and if you were to look at the code of our extensions, you would see it is the same method below as we use ourselves.

Let’s say we have a method:

```swift
func fetch(completion: (String?, Error?) -> Void)
```

How do we convert this to a promise? Well, it's easy:

```swift
func fetch() -> Promise<String> {
    return Promise { foo(completion: $0.resolve) }
}
```

You may provde the expanded version more readable:

```swift
func fetch() -> Promise<String> {
    return Promise { seal in
        foo { result, error in
            seal.resolve(result, error)
        }
    }
}
```

You’ll find the `seal` object the Promise initializer provides you has many
methods for the common variety of completion handlers, and even some rarer
situations thus making it really easy for you to add promises to your existing
codebases.

> Note we tried to make it so you could just do `Promise(fetch)` but we couldn’t
make this simpler pattern work for the wide variety of situations you encounter
without making the 90% case easy to use and un-ambiguous for the Swift compiler.
Sorry, we tried.

> Note with PMK 4 this initializer provided two parameters to your closure,
`fulfill` and `reject`. PMK 5/6 provide an object that has a `fulfill` and
`reject` method, but also many variants of the method `resolve`, you can
typically just pass resolve to completion handler parameters and Swift figures
out which one to use for you.


# `Guarantee<T>`

Since PromiseKit 5 we have provided `Guarantee` as a supplemently class to
`Promise`. We do as a complement to Swift’s strong Error handling system.

Guarantees *never* fail, so they cannot be rejected. A good example is `after`:

```
firstly {
    after(seconds: 0.1)
}.done {
    // there is no way to add a `catch` because after cannot fail.
}
```

Relatedly Swift *warns* you if you don’t terminate a `Promise` (ie. not
`Guarantee`) chain, and the way we expect you to satisfy this warning is to
either `catch` or `return` (where you will then have to `catch`) where you
receive that promise.

Thus use `Guarantee`s wherever possible to force yourself to write code that has
error handling where required and not where not required.

In general you should be able to use `Guarantee`s and `Promise`s interchangably
and we have gone to great lengths to try and ensure this, so please open
tickets if you find an issue.


# `map`, `flatMap`, etc.

`then` provides you the result of the previous promise and requires you return
another promise.

`map` provides you the result of the previous promise and requires you return
an object or value type.

`flatMap` provides you the result of the previous promise and requires you
return an `Optional`, if you return `nil` the chain fails with
`PMKError.flatMap`.

> *Rationale* before PromiseKit 4 `then` handled all these cases, and it was
painful. We imagined the pain would disappear with new Swift versions, however
it has become clear the various pain-points are here to stay, and in fact, we,
as library-authors, are expected to disambiguate at the naming level of our API.
Thus we have split the three main kinds of then out into: `then`, `map` and
`done`. When using these new functions we became enamored and realized this is
much nicer in use, so we added `flatMap` as well (modeled on `Optional.flatMap`)

`flatMap` can be especially useful and enables quick composition of promise
chains, eg:

```swift
firstly {
    URLSession.shared.dataTask(.promise, with: rq)
}.flatMap {
    try JSONSerialization.jsonObject($0.data) as? [String]
}.done { arrayOfStrings in
    //…
}.catch { error in
    // Foundation.JSONError if JSON was badly formed
    // PMKError.flatMap if JSON was not different type
}
```

> *Tip* we provide most of the other functional programming functions that
`Swift` provides, eg. `filter`, `first`, `last`, etc. Use them!

# `get`

We provide `get` as a `done` that returns the value fed to `get`.

```swift
firstly {
    foo()
}.get { foo in
    //…
}.done { foo in
    // same foo!
}
```

# `tap`

We provider `tap` for debugging, it is the same as `get` but provides the
`Result<T>` of the Promise so you can inspect the value of the chain at this
moment without any side-effects:

```swift
firstly {
    foo()
}.tap {
    print($0)
}.done {
    //…
}.catch {
    //…
}
```

# Supplement

## `firstly`

Above we kept using `firstly`, but what is it? Well, it is just [syntactic sugar](https://en.wikipedia.org/wiki/Syntactic_sugar),
you don’t need it, but it helps make your chains more readable. Instead of:

```swift
firstly {
    login()
}.then { creds in
    //…
}
```

You could just do:

```swift
login().then { creds in
    //…
}
```

Here is a key understanding: `login()` returns `Promise` and all `Promise` have a `then` function.

Thus, indeed, `firstly` returns `Promise` and, indeed, `then` returns `Promise`, but don’t worry too much about these details. To start
with learn the *patterns*, then, when you are ready to advance, learn the underlying architecture.

## `when` variants

`when` is one of PromiseKit’s more useful functions, and thus we offer several variants.

* The default `when` and the one you should typically use is `when(fulfilled:)` this variant waits on all its promises, but if any fail, it fails, and thus the chain *rejects*. It is important to note that all promises in the when *continue*. Promises have *no* control over the tasks they represent, promises are merely are wrapper around tasks.
* We provide `when(resolved:)`. This variant waits even if one or more of its promises fails, consequently the result of this promise is an array of `Result<T>`, and consequently this variant requires that all its promises have the same generic type. See our advanced patterns guide for work arounds for this limitation.
* We provide `race`, this variant allows you to *race* several promises, whichever finishes first is the result. See our advanced patterns guide for typical usage.


## Swift Closure Inference

Swift will automatically infer returns and return types for one line closures,
thus these are the same:

```swift
foo.then {
    bar($0)
}

// is the same as:

foo.then { baz -> Promise<String> in
    return bar(baz)
}
```

Our documentation often omits the `return` for clarity.

However this is a blessing and a curse, as the Swift compiler often will fail
to infer return types. See our [Troubleshooting Guide](Troubleshooting.md) if
you require further assistance.

> By adding `done` to PromiseKit 5 we have managed to avoid many of the common
pain points in using PromiseKit and Swift. This was also our justification for
making you specify `.pending` when using the Promise initializer (although this
has been less successful as Swift will choose the `Promise(value:)` initializer
if you don’t specify `.pending` which is our main reason for holding off on
releasing version 5).


# Further Reading

The above is the 90% you will use. We **strongly** suggest reading the
[sources], though strictly we are only suggesting you read the function
documentation, don't worry about the internals. There are numerous little
functions that may be useful to you and the documentation for all of the above
is more thorough at the source.

In Xcode don’t forget to `⌥` click on PromiseKit functions to get at this
documentation while you are developing.

Otherwise return to our [contents page](/Documentation).


[sources]: https://github.com/mxcl/PromiseKit/tree/master/Sources
