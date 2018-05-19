# Common Patterns

One feature of promises that makes them so useful is that they are composable;
enabling complex, yet safe asynchronous patterns that would otherwise be quite
intimidating with traditional methods.


## Chaining

The most common pattern with promises is chaining:

```swift
firstly {
    fetch()
}.then {
    map($0)
}.then {
    set($0)
    return animate()
}.ensure {
    cleanup()
}.catch {
    handle(error: $0)
}
```

If you return a promise in a `then` the next `then` *waits* on that promise
before continuing. This is the essence of promises.

Composing promises is easy, and they thus encourage you to develop great apps
without fear for the typical spaghetti (and associated refactoring pains) of
asynchronous systems that use completion handlers.


## APIs That Use Promises

Promises are composable, return them instead of providing completion blocks:

```swift
class MyRestAPI {
    func user() -> Promise<User> {
        return firstly {
            URLSession.shared.dataTask(.promise, with: url)
        }.compactMap {
            try JSONSerialization.jsonObject(with: $0.data) as? [String: Any]
        }.map { dict in
            User(dict: dict)
        }
    }

    func avatar() -> Promise<UIImage> {
        return user().then { user in
            URLSession.shared.dataTask(.promise, with: user.imageUrl)
        }.compactMap {
            UIImage(data: $0.data)
        }
    }
}
```

This way, your asynchronous systems can easily be engaged in chains all over
your apps.

> Note we provide [promises for Alamofire](https://github.com/PromiseKit/Alamofire-) too!


## Background Work

```swift
class MyRestAPI {
    func avatar() -> Promise<UIImage> {
        let bgq = DispatchQueue.global(qos: .userInitiated)

        return firstly {
            user()
        }.then(on: bgq) { user in
            URLSession.shared.dataTask(.promise, with: user.imageUrl)
        }.compactMap(on: bgq) {
            UIImage(data: $0)
        }
    }
}
```

All PromiseKit handlers take an `on` parameter allowing you to choose the queue
the handler executes upon. The default is always the main queue.

PromiseKit is *entirely* thread safe.

> *Tip* with caution you can have all `then`, `map`, `compactMap`, etc. run on
a background queue, see `PromiseKit.conf`. Note that we suggest only changing
the queue for the `map` suite of functions, thus `done` and `catch` will
continue to run on the main queue which is *usually* what you want.

## Failing Chains

If an error occurs mid chain, simply throw:

```swift
firstly {
    foo()
}.then { baz in
    bar(baz)
}.then { result in
    guard !result.isBad else { throw MyError.myIssue }
    //…
    return doOtherThing()
}
```

The error will surface at the next `catch` handler.

Thus if you call a throwing function, you don't have to wrap it in a `do`:

```swift
foo().then { baz in
    bar(baz)
}.then { result in
    try doOtherThing()
}.catch { error in
    // if doOtherThing() throws, we end up here
}
```

> *Tip* with Swift you can define inline `enum Error` inside the function you
are working at. This isn’t *great* coding practice, but it is better than
avoiding throwing an error because you can’t be bothered to define a good global
`Error` `enum`.


## Abstracting Away Asychronicity

```swift
var fetch = API.fetch()

override func viewDidAppear() {
    fetch.then { items in
        //…
    }
}

func buttonPressed() {
    fetch.then { items in
        //…
    }
}

func refresh() {
    // ensure only one fetch operation happens at a time

    if fetch.isResolved {
        startSpinner()
        fetch = API.fetch().ensure {
            stopSpinner()
        }
    }
    return fetch
}
```

With promises you don’t need to worry about *when* your asynchronous operation
finishes: act like it already has.

> Above we can see that you can call `then` as many times on a promise as you
> like, they will all be executed in the order they were added.


## Chaining Sequences

When you have a series of tasks to perform on an array of data:

```swift
// fade all visible table cells one by one in a “cascading” effect

let fade = Guarantee()
for cell in tableView.visibleCells {
    fade = fade.then {
        UIView.animate(.promise, duration: 0.1) {
            cell.alpha = 0
        }
    }
}
fade.done {
    // finish
}
```

> Note *usually* you want `when()` since `when` executes all the promises in
parallel and thus is much faster to complete. Use the above pattern in
situations where tasks *must* be done sequentially; animation is a good example.

We also provide `when(concurrently:)` which allows you to schedule more than
one promise at a time if required.

## Timeout

```swift
let fetches: [Promise<T>] = makeFetches()
let timeout = after(seconds: 4)

race(when(fulfilled: fetches).asVoid(), timeout).then {
    //…
}
```

`race` continues as soon as one of the promises it watches finishes.

> Common pitfalls: ensure the promises you pass to `race` are the same type.
> The easiest way to ensure this is using `asVoid()`.

> Please note if any promise you pass rejects, then `race` will be rejected.


# Minimum Duration

Sometimes you need something to take *at least* a certain amount of time (eg.
you want to show a spinner for something, but if it shows for less than 0.3
seconds the UI appears broken to the user).

```swift
let waitAtLeast = after(seconds: 0.3)

firstly {
    foo()
}.then {
    waitAtLeast
}.done {
    //…
}
```

The above works because we create the delay before we do work in `foo()`, thus
it will have either already timed-out or we wait whatever amount of the 0.3
seconds remains before the chain continues.


## Cancellation

Promises don’t have a `cancel` function, but they do support cancellation via a
special error type that conforms to the `CancellableError` protocol.

```swift
func foo() -> (Promise<Void>, cancel: () -> Void) {
    let task = Task(…)
    var cancelme = false

    let promise = Promise<Void> { seal in
        task.completion = { value in
            guard !cancelme else { return reject(PMKError.cancelled) }
            seal.fulfill(value)
        }
        task.start()
    }

    let cancel = {
        cancelme = true
        task.cancel()
    }

    return (promise, cancel)
}
```

> Promises don’t have a cancel function because you don’t want code outside of
> your control to be able to cancel your operations *unless* you explicitly want
> that. In cases where you want it, then it varies how it should work depending
> on how the underlying task supports cancellation. Thus we have provided
> primitives but not concrete API.

Cancelled chains do not call a `catch` handler by default. However you can
intercept cancellation if you like:

```swift
foo.then {
    //…
}.catch(policy: .allErrorsIncludingCancellation) {
    // cancelled errors are handled *as well*
}
```

**Important**, canceling the chain is *not* the same as canceling the underlying
asynchronous task. Promises are a wrapper around asynchronicity but they have no
control over the underlying tasks. If you need to cancel the underlying task you
need to cancel the underlying task!

> The library [CancellablePromiseKit](https://github.com/johannesd/CancellablePromiseKit) extends the concept of Promises to fully cover cancellable tasks.

## Retry / Polling

```swift
func attempt<T>(maximumRetryCount: Int = 3, delayBeforeRetry: DispatchTimeInterval = .seconds(2), _ body: @escaping () -> Promise<T>) -> Promise<T> {
    var attempts = 0
    func attempt() -> Promise<T> {
        attempts += 1
        return body().recover { error -> Promise<T> in
            guard attempts < maximumRetryCount else { throw error }
            return after(delayBeforeRetry).then(on: nil, attempt)
        }
    }
    return attempt()
}

attempt(maximumRetryCount: 3) {
    flakeyTask(parameters: foo)
}.then {
    //…
}.catch { _ in
    // we attempted three times but still failed
}
```

Probably you should supplement the above so that you only re-attempt for
specific error conditions.


## Wrapping Delegate Systems

Be careful with Promises and delegate systems as they are not always suited.
Promises complete *once* where most delegate systems call their callbacks many
times. This is why, for example, there is no PromiseKit extension for a
`UIButton`.

A good example of an appropriate time to wrap delegation is when you need a
single `CLLocation` lookup:

```swift
extension CLLocationManager {
    static func promise() -> Promise<CLLocation> {
        return PMKCLLocationManagerProxy().promise
    }
}

class PMKCLLocationManagerProxy: NSObject, CLLocationManagerDelegate {
    private let (promise, seal) = Promise<[CLLocation]>.pending()
    private var retainCycle: PMKCLLocationManagerProxy?
    private let manager = CLLocationManager()

    init() {
        super.init()
        retainCycle = self
        manager.delegate = self // does not retain hence the `retainCycle` property

        promise.ensure {
            // ensure we break the retain cycle
            self.retainCycle = nil
        }
    }

    @objc fileprivate func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        seal.fulfill(locations)
    }

    @objc func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        seal.reject(error)
    }
}

// use:

CLLocationManager.promise().then { locations in
    //…
}.catch { error in
    //…
}
```

> Please note, we provide this promise with our CoreLocation extensions at
> https://github.com/PromiseKit/CoreLocation


## Recovery

Sometimes you don’t want an error to cascade, instead you have a default value:

```swift
CLLocationManager.requestLocation().recover { error -> Promise<CLLocation> in
    guard error == MyError.airplaneMode else {
        throw error
    }
    return .value(CLLocation.savannah)
}.done { location in
    //…
}
```

Be careful not to ignore all errors; recover only those errors that make sense.


## Promises for modal view-controllers

```swift
class ViewController: UIViewController {

    private let (promise, seal) = Guarantee<…>.pending()  // use Promise if your flow can fail

    func show(in: UIViewController) -> Promise<…> {
        in.show(self, sender: in)
        return promise
    }

    func done() {
        dismiss(animated: true)
        seal.fulfill(…)
    }
}

// use:

ViewController().show(in: self).done {
    //…
}.catch { error in
    //…
}
```

This is the best approach we have found, which is a pity as it requires the
presentee to control the presentation and the presentee to be dismiss itself
explicitly.

Nothing seemingly can beat Storyboard segues for decoupling an app's router.


## Saving previous results

Let’s say you have:


```swift
login().then { username in
    fetch(avatar: username)
}.done { image in
    //…
}
```

What if you want access to both `username` and `image` in your `done`?

The most obvious way is with nesting:

```swift
login().then { username in
    fetch(avatar: username).done { image in
        // we have access to both `image` and `username`
    }
}.done {
    // the chain still continues as you'd expect
}
```

However this nesting reduces the chain’s clarity; instead we could use Swift
tuples:

```swift
login().then { username in
    fetch(avatar: username).map { ($0, username) }
}.then { image, username in
    //…
}
```

The above simply maps `Promise<String>` into `Promise<(UIImage, String)>`.


## Waiting on multiple promises whatever their result

Use `when(resolved:)`:

```swift
when(resolved: a, b).done { (results: [Result<T>]) in
    // `Result` is an enum of `.fulfilled` or `.rejected`
}

// ^^ cannot call `catch` as `when(resolved:)` returns a `Guarantee`
```

Generally you don't want this, people ask for it a lot, but usually they
actually just want to use `recover` on one of the promises. Usually you don't
want to ignore errors. Errors happen, they should be handled.
