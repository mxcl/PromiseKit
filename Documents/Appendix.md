# Common Misusage

## Doubling up Promises

Don’t do this:

```swift
func toggleNetworkSpinnerWithPromise<T>(funcToCall: () -> Promise<T>) -> Promise<T> {
    return Promise { seal in
        firstly {
            setNetworkActivityIndicatorVisible(true)
            return funcToCall()
        }.then { result in
            seal.fulfill(result)
        }.always {
            setNetworkActivityIndicatorVisible(false)
        }.catch { err in
            seal.reject(err)
        }
    }
}
```

Do this:

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

You already *had* a promise, you don’t need to wrap it in another promise.


## Optionals in Promises

When we see `Promise<Item?>`, it usually implies a misuse of promises. For
example:

```swift
return firstly {
    getItems()
}.then { items -> Promise<[Item]?> in
    guard !items.isEmpty else {
        return .value(nil)
    }
    return Promise(value: items)
}
```

The second `then` chooses to return `nil` in some circumstances. This choice
imposes the need to check for `nil` on the consumer of the promise.

It's usually better to shunt these sorts of exceptions away from the
happy path and onto the error path. In this case, we can create a specific
error type for this condition:

```swift
return firstly {
    getItems()
}.map { items -> [Item]> in
    guard !items.isEmpty else {
        throw MyError.emptyItems
    }
    return items
}
```

> *Note*: Use `compactMap` when an API outside your control returns an Optional and you want to generate an error instead of propagating `nil`.

# Tips n’ Tricks

## Background-Loaded Member Variables

```swift
class MyViewController: UIViewController {
    private let ambience: Promise<AVAudioPlayer> = DispatchQueue.global().async(.promise) {
        guard let asset = NSDataAsset(name: "CreepyPad") else { throw PMKError.badInput }
        let player =  try AVAudioPlayer(data: asset.data)
        player.prepareToPlay()
        return player
    }
}
```

## Chaining Animations

```swift
firstly {
    UIView.animate(.promise, duration: 0.3) {
        self.button1.alpha = 0
    }
}.then {
    UIView.animate(.promise, duration: 0.3) {
        self.button2.alpha = 1
    }
}.then {
    UIView.animate(.promise, duration: 0.3) {
        adjustConstraints()
        self.view.layoutIfNeeded()
    }
}
```


## Voiding Promises

It is often convenient to erase the type of a promise to facilitate chaining.
For example, `UIView.animate(.promise)` returns `Guarantee<Bool>` because UIKit’s
completion API supplies a `Bool`. However, we usually don’t need this value and 
can chain more simply if it is discarded (that is, converted to `Void`). We can use
`asVoid()` to achieve this conversion:

```swift
UIView.animate(.promise, duration: 0.3) {
    self.button1.alpha = 0
}.asVoid().done(self.nextStep)
```

For situations in which we are combining many promises into a `when`, `asVoid()`
becomes essential:

```swift
let p1 = foo()
let p2 = bar()
let p3 = baz()
//…
let p10 = fluff()

when(fulfilled: p1.asVoid(), p2.asVoid(), /*…*/, p10.asVoid()).then {
    let value1 = p1.value!  // safe bang since all the promises fulfilled
    // …
    let value10 = p10.value!
}.catch {
    //…
}
```

You normally don't have to do this explicitly because `when` does it for you
for up to 5 parameters.


## Blocking (Await)

Sometimes you have to block the main thread to await completion of an asynchronous task.
In these cases, you can (with caution) use `wait`:

```swift
public extension UNUserNotificationCenter {
    var wasPushRequested: Bool {
        let settings = Guarantee(resolver: getNotificationSettings).wait()
        return settings != .notDetermined
    }
}
```

The task under the promise **must not** call back onto the current thread or it
will deadlock.

## Starting a Chain on a Background Queue/Thread

`firstly` deliberately does not take a queue. A detailed rationale for this choice
can be found in the ticket tracker.

So, if you want to start a chain by dispatching to the background, you have to use
`DispatchQueue.async`:

```swift
DispatchQueue.global().async(.promise) {
    return value  
}.done { value in
    //…
}
```

However, this function cannot return a promise because of Swift compiler ambiguity
issues. Thus, if you must start a promise on a background queue, you need to
do something like this:


```swift
Promise { seal in
    DispatchQueue.global().async {
        seal(value)
    }  
}.done { value in
    //…
}
```

Or more simply (though with caveats; see the documentation for `wait`):

```swift
DispatchQueue.global().async(.promise) {
    return try fetch().wait()
}.done { value in
    //…
}
```

However, you shouldn't need to do this often. If you find yourself wanting to use
this technique, perhaps you should instead modify the code for `fetch` to make it do
its work on a background thread.

Promises abstract asynchronicity, so exploit and support that model. Design your
APIs so that consumers don’t have to care what queue your functions run on.

##  `Dispatcher` Objects

Some issues are best addressed at the level of dispatching. For example, you may need
to perform a series of HTTP transactions on a server that allows only a certain number of
API calls per minute. Or, you might want to allow only a certain number of memory-hungry
background tasks to run at once. These aren't really promise-level concerns; they just have
to do with the details of how closures are invoked once they become eligible to run.

Unfortunately, `DispatchQueue`s don't directly support these types of restrictions, and because
of the way `DispatchQueue` is implemented, you can't create your own subclasses. PromiseKit 7 
adds an abstract `Dispatcher` protocol that generalizes the idea of a dispatch queue and allows for
alternate implementations:

```swift
public protocol Dispatcher {
    func dispatch(_ body: @escaping () -> Void)
}
```

Anywhere in PromiseKit that you can use a `DispatchQueue`, you're free to substitute a `Dispatcher`. 

PromiseKit doesn't care how you implement `dispatch()`. You can run the provided closure synchronously or
asynchronously, now or at some point in the future, on any thread you wish. Of course, your own code 
must have a thread safety strategy and not create deadlocks.

If you're setting a default dispatcher, assign your dispatcher to `PromiseKit.conf.D` rather than `PromiseKit.conf.Q`; the latter
accepts only `DispatchQueue`s.

**FIXME: Check locations and availability of Dispatcher implementations before release**

A few handy `Dispatcher` types are available in the `Dispatchers` extension library:

* `RateLimitedDispatcher` implements general dispatch rate limits with an approximate "token bucket" strategy.
* `StrictRateLimitedDispatcher` is an exact and optimal "sliding window" rate limiter, but requires O(n) space (n = # of events/time)
* `ConcurrencyLimitedDispatcher` allows only *n* asynchronous closures to run at once.
* `CoreDataDispatcher` lets you dispatch onto threads associated with `NSManagedObjectContext`s.

A couple of `Dispatcher`s are also included in the PromiseKit core: 

* `CurrentThreadDispatcher` runs closures immediately, on the current thread.
* `DispatchQueueDispatcher` forwards to a `DispatchQueue`, applying a static `DispatchGroup`, quality of service, and flag set.
