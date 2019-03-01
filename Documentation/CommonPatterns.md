# Common Patterns

One feature of promises that makes them particularly useful is that they are composable.
This fact enables complex, yet safe asynchronous patterns that would otherwise be quite
intimidating when implemented with traditional methods.


## Chaining

The most common pattern is chaining:

```swift
firstly {
    fetch()
}.then {
    map($0)
}.then {
    set($0)
    return animate()
}.ensure {
    // something that should happen whatever the outcome
}.catch {
    handle(error: $0)
}
```

If you return a promise in a `then`, the next `then` *waits* on that promise
before continuing. This is the essence of promises.

Promises are easy to compose, so they encourage you to develop highly asynchronous
apps without fear of the spaghetti code (and associated refactoring pains) of
asynchronous systems that use completion handlers.


## APIs That Use Promises

Promises are composable, so return them instead of accepting completion blocks:

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

This way, asynchronous chains can cleanly and seamlessly incorporate code from all over
your app without violating architectural boundaries.

> *Note*: We provide [promises for Alamofire](https://github.com/PromiseKit/Alamofire-) too!


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

All PromiseKit handlers take an `on` parameter that lets you designate the dispatch queue
on which to run the handler. The default is always the main queue.

PromiseKit is *entirely* thread safe.

> *Tip*: With caution, you can have all `then`, `map`, `compactMap`, etc., run on
a background queue. See `PromiseKit.conf`. Note that we suggest only changing
the queue for the `map` suite of functions, so `done` and `catch` will
continue to run on the main queue, which is *usually* what you want.

## Failing Chains

If an error occurs mid-chain, simply throw an error:

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

Since promises handle thrown errors, you don't have to wrap calls to throwing functions 
in a `do` block unless you really want to handle the errors locally:

```swift
foo().then { baz in
    bar(baz)
}.then { result in
    try doOtherThing()
}.catch { error in
    // if doOtherThing() throws, we end up here
}
```

> *Tip*: Swift lets you define an inline `enum Error` inside the function you
are working on. This isn’t *great* coding practice, but it's better than
avoiding throwing an error because you couldn't be bothered to define a good global
`Error` `enum`.


## Abstracting Away Asynchronicity

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

func refresh() -> Promise {
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

With promises, you don’t need to worry about *when* your asynchronous operation
finishes. Just act like it already has.

Above, we see that you can call `then` as many times on a promise as you
like. All the blocks will be executed in the order they were added.


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

Or if you have an array of promises:

```swift
var foo = Promise()
for nextPromise in arrayOfPromises {
    foo = foo.then { nextPromise }
}
foo.done {
    // finish
}
```

> *Note*: You *usually* want `when()`, since `when` executes all of its
component promises in parallel and so completes much faster. Use the pattern 
shown above in situations where tasks *must* be run sequentially; animation
is a good example.

> We also provide `when(concurrently:)`, which lets you schedule more than
one promise at a time if you need to.

## Timeout

```swift
let fetches: [Promise<T>] = makeFetches()
let timeout = after(seconds: 4)

race(when(fulfilled: fetches).asVoid(), timeout).then {
    //…
}
```

`race` continues as soon as one of the promises it is watching finishes.

Make sure the promises you pass to `race` are all of the same type. The easiest way
to ensure this is to use `asVoid()`.

Note that if any component promise rejects, the `race` will reject, too.


# Minimum Duration

Sometimes you need a task to take *at least* a certain amount of time. (For example,
you want to show a progress spinner, but if it shows for less than 0.3 seconds, the UI
appears broken to the user.)

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

The code above works because we create the delay *before* we do work in `foo()`. By the 
time we get to waiting on that promise, either it will have already timed out or we will wait
for whatever remains of the 0.3 seconds before continuing the chain.


## Cancellation

Promises don’t have a `cancel` function, but they do support cancellation through a
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

Promises don’t have a `cancel` function because you don’t want code outside of
your control to be able to cancel your operations--*unless*, of course, you explicitly
want to enable that behavior. In cases where you do want cancellation, the exact way 
that it should work will vary depending on how the underlying task supports cancellation.
PromiseKit provides cancellation primitives but no concrete API.

Cancelled chains do not call `catch` handlers by default. However you can
intercept cancellation if you like:

```swift
foo.then {
    //…
}.catch(policy: .allErrors) {
    // cancelled errors are handled *as well*
}
```

**Important**: Canceling a promise chain is *not* the same as canceling the underlying
asynchronous task. Promises are wrappers around asynchronicity, but they have no
control over the underlying tasks. If you need to cancel an underlying task, you
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

In most cases, you should probably supplement the code above so that it re-attempts only for
specific error conditions.


## Wrapping Delegate Systems

Be careful with Promises and delegate systems, as they are not always compatible.
Promises complete *once*, whereas most delegate systems may notify their delegate many
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

> Please note: we provide this promise with our CoreLocation extensions at
> https://github.com/PromiseKit/CoreLocation


## Recovery

Sometimes you don’t want an error to cascade. Instead, you want to supply a default result:

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

Be careful not to ignore all errors, though! Recover only those errors that make sense to recover.


## Promises for Modal View Controllers

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
presentee to control the presentation and requires the presentee to dismiss itself
explicitly.

Nothing seems to beat storyboard segues for decoupling an app's controllers.


## Saving Previous Results

Let’s say you have:


```swift
login().then { username in
    fetch(avatar: username)
}.done { image in
    //…
}
```

What if you want access to both `username` and `image` in your `done`?

The most obvious way is to use nesting:

```swift
login().then { username in
    fetch(avatar: username).done { image in
        // we have access to both `image` and `username`
    }
}.done {
    // the chain still continues as you'd expect
}
```

However, such nesting reduces the clarity of the chain. Instead, we could use Swift
tuples:

```swift
login().then { username in
    fetch(avatar: username).map { ($0, username) }
}.then { image, username in
    //…
}
```

The code above simply maps `Promise<String>` into `Promise<(UIImage, String)>`.


## Waiting on Multiple Promises, Whatever Their Result

Use `when(resolved:)`:

```swift
when(resolved: a, b).done { (results: [Result<T>]) in
    // `Result` is an enum of `.fulfilled` or `.rejected`
}

// ^^ cannot call `catch` as `when(resolved:)` returns a `Guarantee`
```

Generally, you don't want this! People ask for it a lot, but usually because
they are trying to ignore errors. What they really need is to use `recover` on one of the
promises. Errors happen, so they should be handled; you usually don't want to ignore them.
