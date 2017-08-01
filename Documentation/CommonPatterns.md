# Common Patterns

One feature of promises that makes them so useful is that thet are composable;
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
        return URLSession.shared.dataTask(url).asDictionary().then { dict in
            return User(dict: dict)
        }
    }

    func avatar() -> Promise<UIImage> {
        return user().then { user in
            URLSession.shared.dataTask(user.imageUrl)
        }.then {
            UIImage(data: $0)
        }
    }
}
```

This way, your asynchronous systems can easily be engaged in chains all over
your apps.


## Background Work

```swift
class MyRestAPI {
    func avatar() -> Promise<UIImage> {
        let bgq = DispatchQueue.global(qos: .userInitiated)
        
        return user().then(on: bgq) { user in
            URLSession.shared.dataTask(user.imageUrl)
        }.then(on: bgq) {
            UIImage(data: $0)
        }
    }
}
```

All PromiseKit handlers take an `on` parameter allowing you to choose the queue
the handler executes upon. The default is always the main queue.

PromiseKit is *entirely* thread safe.


## Failing Chains

If an error occurs mid chain, simply throw:

```swift
foo().then { baz in
    return bar(baz)
}.then { result in
    if result.isBad { throw MyError.myIssue }
    //…
    return doOtherThing()
}
```

The error will surface at the next `catch` handler.

Thus if you call a throwing function, you don't have to wrap it in a `do`:

```swift
foo().then { baz in
    return bar(baz)
}.then { result in
    return try doOtherThing()
}.catch { error in
    // if doOtherThing() throws, we end up here
}
```


## Abstracting Away Asychronicity

```switch
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

let fade = Promise()
for cell in tableView.visibleCells {
    fade = fade.then {
        UIView.promise(animateWithDuration:0.1) {
            cell.alpha = 0
        }
    }
}
fade.then {
    //finish
}
```

Note *usually* you want `when()` since `when` executes all the promises in
parallel and thus is much faster to complete. Use the above pattern in
situations where tasks *must* be done sequentially; animation is a good example.


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


## Cancellation

Promises don’t have a `cancel` function, but they do support cancellation via a
special error type that conforms to the `CancellableError` protocol.

```swift
func foo() -> (Promise<Void>, cancel: () -> Void) {
    var cancelme = false

    let promise = Promise<Void> { fulfill, reject in
        let task = Task(…)
        let cancel = {
            cancelme = true
            task.cancel()
            reject(NSError.cancelledError)
        }
        task.completion = { value in
            guard !cancelme else { reject(NSError.cancelledError) }
            fulfill(value)
        task.start()
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

## Retry / Polling

```swift
func attempt<T>(interdelay: DispatchTimeInterval = .seconds(2), maxRepeat: Int = 3, body: @escaping () -> Promise<T>) -> Promise<T> {
    var attempts = 0
    func attempt() -> Promise<T> {
        attempts += 1
        return body().recover { error -> Promise<T> in
            guard attempts < maxRepeat else { throw error }

            return after(interval: interdelay).then {
                return attempt()
            }
        }
    }

    return attempt()
}

attempt{ flakeyTask() }.then {
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
    private let (promise, fulfill, reject) = Promise<[CLLocation]>.pending()
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
        fulfill(locations)
    }

    @objc func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        reject(error)
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

```
CLLocationManager.promise().recover { error -> CLLocation in
    guard error == MyError.airplaneMode else {
        throw error
    }
    return CLLocation.savannah
}.then { location in
    //…
}
```

Be careful not to ignore all errors; recover only those errors that make sense.


## Promises for modal view-controllers

```swift
class ViewController: UIViewController {

    private let (promise, seal) = Promise<…>.pending()
    
    func show(in: UIViewController) -> Promise<…> {
        in.show(self, sender: in)
        return promise
    }
    
    func done() {
        dismiss(animated: true)
        seal(…)
    }
}

// use:

ViewController().show(in: self).then {
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
}.then { image in
    //…
}
```

In the second `then` how can you access `username` as well as `image`?

The most obvious way is with nesting:

```swift
login().then { username in
    fetch(avatar: username).then { image in
        // we have image and username
    }
}.then {
    // the chain still continues as you'd expect
}
```

However you could instead use Swift tuples:

```swift
login().then { username in
    fetch(avatar: username).then { ($0, username) }
}.then { image, username in
    //…
}
```

The above is a quick transforming `then` that simply maps the `Promise<String>`
into `Promise<(UIImage, String)>`.


## Waiting on multiple promises whatever their result

Use `when(resolved:)`:

```swift
when(resolved: a, b).then { (results: [Result<T>]) in
    // `Result` is an enum of `.fulfilled` or `.rejected`
}
```

Generally you don't want this, people ask for it a lot, but usually they
actually just want to use `recover` on one of the promises. Usually you don't
want to ignore errors. Errors happen, they should be handled.
