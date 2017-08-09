# `then`

Here is a typical promise chain:

```swift
firstly {
    login()
}.then { creds in
    fetch(avatar: creds.user)
}.then { image in
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

`then` *is* just another way to do completion handlers, but it is also quite a bit more. At this
initial stage of our understanding it merely helps readability. The promise chain above is easy
to read, one asynchronous operation leads into the other, read line by line. It's as close to
procedural code as we can easily get with the current state of Swift.

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

A Promise represents the future value of an asynchronous task. It has a type
that represents the type of object it wraps. In the above example `login` is a
function that returns a `Promise` that *will* represent an instance of `Creds`.

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
}.then { image in
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


# `always`

We have learned to compose asynchronicity. Next let’s extend our primitives:

```swift
firstly {
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
    return login()
}.then {
    fetch(avatar: $0.user)
}.then {
    self.imageView = $0
}.always {
    UIApplication.shared.isNetworkActivityIndicatorVisible = false
}.catch {
    //…
}
```

Whatever the outcome in your chain—failure or success—your `always`
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
}.then { result1, result2 in
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
}.then { placemarks in
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
    return PromiseKit.wrap(fetch) }
}
```

For more complicated situations use the root-resolver:

```swift
func fetch() -> Promise<String> {
    return Promise { fulfill, reject in
        foo { result, error in
            if let result = result {
                fulfill(result)
            } else if let error = error {
                fulfill(error)
            } else {
                reject(PMKError.invalidCallingConvention)
                // ^^ we provide this error so that all paths are handled, even
                // this path which technically should never happen (but might!)
            }
        }
    }
}
```

Note with the above example `PromiseKit.wrap(foo)` *would* have worked.
Only use the root-resolver when wrap doesn’t work *or* you need to handle
non-typical scenarios.

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
