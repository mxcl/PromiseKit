# `then` and `done`

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

If this code used completion handlers, it would look like this:

```swift
login { creds, error in
    if let creds = creds {
        fetch(avatar: creds.user) { image, error in
            if let image = image {
                self.imageView = image
            }
        }
    }
}
```

`then` *is* just another way to structure completion handlers, but it is also quite a
bit more. At this initial stage of our understanding, it mostly helps
readability. The promise chain above is easy to scan and understand: one asynchronous
operation leads into the other, line by line. It's as close to
procedural code as we can easily come given the current state of Swift.

`done` is the same as `then` but you cannot return a promise. It is 
typically the end of the “success” part of the chain. Above, you can see that we
receive the final image in our `done` and use it to set up the UI.

Let’s compare the signatures of the two login methods:

```swift
func login() -> Promise<Creds>
    
// Compared with:

func login(completion: (Creds?, Error?) -> Void)
                        // ^^ ugh. Optionals. Double optionals.
```

The distinction is that with promises, your functions return *promises* instead 
of accepting and running callbacks. Each handler in a chain returns a promise. 
`Promise` objects define the `then` method, which waits for the completion of the
promise before continuing the chain. Chains resolve procedurally, one promise
at a time.

A `Promise` represents the future value of an asynchronous task. It has a type
that represents the type of object it wraps. For example, in the example above,
`login` is a function that returns a `Promise` that *will* represent an instance
of `Creds`.

> *Note*: `done` is new to PromiseKit 5. We previously defined a variant of `then` that
did not require you to return a promise. Unfortunately, this convention often confused
Swift and led to odd and hard-to-debug error messages. It also made using PromiseKit 
more painful. The introduction of `done` lets you type out promise chains that
compile without additional qualification to help the compiler figure out type information.

---

You may notice that unlike the completion pattern, the promise chain appears to
ignore errors. This is not the case! In fact, it has the opposite effect: the promise
chain makes error handling more accessible and makes errors harder to ignore.


# `catch`

With promises, errors cascade along the promise chain, ensuring that your apps are
robust and your code is clear:

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

> Swift emits a warning if you forget to `catch` a chain. But we'll
> talk about that in more detail later.

Each promise is an object that represents an individual, asynchronous task.
If a task fails, its promise becomes *rejected*. Chains that contain rejected
promises skip all subsequent `then`s. Instead, the next `catch` is executed.
(Strictly speaking, *all* subsequent `catch` handlers are executed.)

For fun, let’s compare this pattern with its completion handler equivalent:

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

The use of `guard` and a consolidated error handler help, but the promise chain’s
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

No matter the outcome of your chain—-failure or success—-your `ensure`
handler is always called.

Let’s compare this pattern with its completion handler equivalent:

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

It would be very easy for someone to amend this code and forget to unset 
the activity indicator, leading to a bug. With promises, this type of error is
almost impossible: the Swift compiler resists your supplementing the chain without 
using promises. You almost won’t need to review the pull requests.

> *Note*: PromiseKit has perhaps capriciously switched between the names `always`
and `ensure` for this function several times in the past. Sorry about this. We suck.

You can also use `finally` as an `ensure` that terminates the promise chain and does not return a value:

```
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


# `when`

With completion handlers, reacting to multiple asynchronous operations is either
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
group.notify(queue: .main) {
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

`when` takes promises, waits for them to resolve and returns a promise containing the results.

As with any promise chain, if any of the component promises fail, the chain calls the next `catch`.


# PromiseKit Extensions

When we made PromiseKit, we understood that we wanted to use *only* promises to implement 
asynchronous behavior. So wherever possible, we offer extensions to Apple’s APIs that reframe
the API in terms of promises. For example:

```swift
firstly {
    CLLocationManager.promise()
}.then { location in
    CLGeocoder.reverseGeocode(location)
}.done { placemarks in
    self.placemark.text = "\(placemarks.first)"
}
```

To use these extensions, you need to specify subspecs:

```ruby
pod "PromiseKit"
pod "PromiseKit/CoreLocation"
pod "PromiseKit/MapKit"
```

All of these extensions are available at the [PromiseKit organization](https://github.com/PromiseKit).
Go there to see what's available and to read the source code and documentation. Every file and function
has been copiously documented.

> We also provide extensions for common libraries such as [Alamofire](https://github.com/PromiseKit/Alamofire-).


# Making Promises

The standard extensions will take you a long way, but sometimes you'll still need to start chains
of your own. Maybe you're using a third party API that doesn’t provide promises, or perhaps you wrote
your own asynchronous system. Either way, it's easy to add promises. If you look at the code of the
standard extensions, you'll see that it uses the same approach  described below.

Let’s say we have the following method:

```swift
func fetch(completion: (String?, Error?) -> Void)
```

How do we convert this to a promise? Well, it's easy:

```swift
func fetch() -> Promise<String> {
    return Promise { fetch(completion: $0.resolve) }
}
```

You may find the expanded version more readable:

```swift
func fetch() -> Promise<String> {
    return Promise { seal in
        fetch { result, error in
            seal.resolve(result, error)
        }
    }
}
```

The `seal` object that the `Promise` initializer provides to you defines 
many methods for handling garden-variety completion handlers. It even 
covers a variety of rarer situations, thus making it easy for you to add 
promises to an existing codebase.

> *Note*: We tried to make it so that you could just do `Promise(fetch)`, but we
were not able to make this simpler pattern work universally without requiring
extra disambiguation for the Swift compiler. Sorry; we tried.

> *Note*: In PMK 4, this initializer provided two parameters to your closure:
`fulfill` and `reject`. PMK 5 and 6 give you an object that has both `fulfill` and
`reject` methods, but also many variants of the method `resolve`. You can
typically just pass completion handler parameters to `resolve` and let Swift figure
out which variant to apply to your particular case (as shown in the example above).

> *Note* `Guarantees` (below) have a slightly different initializer (since they
cannot error) so the parameter to the initializer closure is just a closure. Not
a `Resolver` object. Thus do `seal(value)` rather than `seal.fulfill(value)`. This
is because there is no variations in what guarantees can be sealed with, they can
*only* fulfill.

# `Guarantee<T>`

Since PromiseKit 5, we have provided `Guarantee` as a supplementary class to
`Promise`. We do this to complement Swift’s strong error handling system.

Guarantees *never* fail, so they cannot be rejected. A good example is `after`:

```
firstly {
    after(seconds: 0.1)
}.done {
    // there is no way to add a `catch` because after cannot fail.
}
```

Swift warns you if you don’t terminate a regular `Promise` chain (i.e., not
a `Guarantee` chain). You're expected to silence this warning by supplying 
either a `catch` or a `return`. (In the latter case, you will then have to `catch` 
at the point where you receive that promise.)

Use `Guarantee`s wherever possible so that your code has error handling where
it's required and no error handling where it's not required.

In general, you should be able to use `Guarantee`s and `Promise`s interchangeably,
We have gone to great lengths to try and ensure this, so please open a ticket
if you find an issue.

---

If you are creating your own guarantees the syntax is simpler than that of promises;

```swift
func fetch() -> Promise<String> {
    return Guarantee { seal in
        fetch { result in
            seal(result)
        }
    }
}
```

Which could be reduced to:

```swift
func fetch() -> Promise<String> {
    return Guarantee(resolver: fetch)
}
```

# `map`, `compactMap`, etc.

`then` provides you with the result of the previous promise and requires you to return
another promise.

`map` provides you with the result of the previous promise and requires you to return
an object or value type.

`compactMap` provides you with the result of the previous promise and requires you
to return an `Optional`. If you return `nil`, the chain fails with
`PMKError.compactMap`.

> *Rationale*: Before PromiseKit 4, `then` handled all these cases, and it was
painful. We hoped the pain would disappear with new Swift versions. However,
it has become clear that the various pain points are here to stay. In fact, we
as library authors are expected to disambiguate at the naming level of our API.
Therefore, we have split the three main kinds of `then` into `then`, `map` and
`done`. After using these new functions, we realized this is much nicer in practice,
so we added `compactMap` as well (modeled on `Optional.compactMap`).

`compactMap` facilitates quick composition of promise chains. For example:

```swift
firstly {
    URLSession.shared.dataTask(.promise, with: rq)
}.compactMap {
    try JSONSerialization.jsonObject($0.data) as? [String]
}.done { arrayOfStrings in
    //…
}.catch { error in
    // Foundation.JSONError if JSON was badly formed
    // PMKError.compactMap if JSON was of different type
}
```

> *Tip*: We also provide most of the functional methods you would expect for sequences,
e.g., `map`, `thenMap`, `compactMapValues`, `firstValue`, etc.


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

We provide `tap` for debugging. It's the same as `get` but provides the
`Result<T>` of the `Promise` so you can inspect the value of the chain at this
point without causing any side effects:

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

We've used `firstly` several times on this page, but what is it, really? In fact,
it is just [syntactic sugar](https://en.wikipedia.org/wiki/Syntactic_sugar).
You don’t really need it, but it helps to make your chains more readable. Instead of:

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

Here is a key understanding: `login()` returns a `Promise`, and all `Promise`s have a `then` function. `firstly` returns a `Promise`, and `then` returns a `Promise`, too! But don’t worry too much about these details. Learn the *patterns* to start with. Then, when you are ready to advance, learn the underlying architecture.


## `when` Variants

`when` is one of PromiseKit’s more useful functions, and so we offer several variants.

* The default `when`, and the one you should typically use, is `when(fulfilled:)`. This variant
waits on all its component promises, but if any fail, `when` fails too, and thus the chain *rejects*. 
It's important to note that all promises in the `when` *continue*. Promises have *no* control over
the tasks they represent. Promises are just wrappers around tasks.

* `when(resolved:)` waits even if one or more of its component promises fails. The value produced
by this variant of `when` is an array of `Result<T>`. Consequently, this variant requires all its 
component promises to have the same generic type. See our advanced patterns guide for work-arounds
for this limitation.

* The `race` variant lets you *race* several promises. Whichever finishes first is the result. See the
advanced patterns guide for typical usage.


## Swift Closure Inference

Swift automatically infers returns and return types for one-line closures.
The following two forms are the same:

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

However, this shorthand is both a blessing and a curse. You may find that the Swift compiler
often fails to infer return types properly. See our [Troubleshooting Guide](Troubleshooting.md) if
you require further assistance.

> By adding `done` to PromiseKit 5, we have managed to avoid many of these common
pain points in using PromiseKit and Swift.



# Further Reading

The above information is the 90% you will use. We **strongly** suggest reading the
[API Reference].
There are numerous little
functions that may be useful to you, and the documentation for everything outlined above
is more thorough at the source.

In Xcode, don’t forget to option-click on PromiseKit functions to access this
documentation while you're coding.

Here are some recent articles that document PromiseKit 5+:

* [Using Promises - Agostini.tech](https://agostini.tech/2018/10/08/using-promisekit)

Careful with general online references, many of them refer to PMK < 5 which has a subtly
different API (sorry about that, but Swift has changed a lot over the years and thus
we had to too).


[API Reference]: https://mxcl.dev/PromiseKit/reference/v6/Classes/Promise.html
