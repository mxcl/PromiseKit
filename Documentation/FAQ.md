# FAQ

## Do I need to worry about retain cycles?

Generally no, provided the promise completes then all handlers are released thus
any references to `self` are also released.

This does mean that if your chain contains side-effects that you would typically
not want to happen after, say, a view controller is popped then you should still
use `weak self` (and check for `self == nil`) to prevent any such side-effects.

[This stackoverflow question](https://stackoverflow.com/questions/39281214/should-i-use-weak-self-in-promisekit-blocks)
has some good discussion on the topic.

## Where should I put my `catch`?

`catch` deliberately terminates the chain, you should place low in your promise
heirarchy: at as root a point as possible. Typically this would be your view
controllers where your `catch` can then display a message to the user.

This means you should be writing one catch for many `then`s and be returning
promises without there being `catch` handlers.

This is obviously a guideline, do what is necessary.

## How do branched chains work?

If you have a promise:

```
let promise = foo()
```

And you call `then` twice:

```
promise.then {
    // branch A
}

promise.then {
    // branch B
}
```

You now have a branched chain. When `promise` resolves both chains receive its
value. However the two chains are entirely separate and Swift will prompt you
to ensure both have `catch` handlers.

Probably however you can ignore the catch for one, but be careful in these
situations as Swift cannot help you ensure your chains are error handled.

```
promise.then {
    // branch A
}.catch { error in
    //…
}

_ = promise.then {
    print("foo")
    
    // ignoring errors here as print cannot error and we handle errors above
}
```

It may be safer to recombine the two branches into a single chain again:

```
let p1 = promise.then {
    // branch A
}

let p2 = promise.then {
    // branch B
}

when(fulfilled: p1, p2).catch { error in
    //…
}
```

> It's worth noting that you can add multiple `catch` handlers to a promise too,
> and indeed, both will be called if the chain is rejected.

## Is PromiseKit “heavy”?

No, PromiseKit is hardly any sources in fact, it’s actually pretty light. Any
weight relative to other promise implementations is 6 years of bug fixes.

## Why is debugging hard?

Because promises always execute via `dispatch` the backtraces you get have less
information than is often required to trace the path of execution.

One solution is (during debugging) to turn off the dispatch:

```swift
// Swift
DispatchQueue.default = zalgo

//ObjC
PMKSetDefaultDispatchQueue(zalgo)
```

Don’t leave this is on, we always dispatch to avoid you accidentally writing
a common bug pattern: http://blog.izs.me/post/59142742143/designing-apis-for-asynchrony

## Where is `all()`?

Some promise libraries provide `all`, we provide `when`, it is the same. `when`
was chosen as it is the more common choice which we also think reads better.


## How can I test APIs that return promises?

You need to use `XCTestExpectation`.

## Is PromiseKit thread-safe?

Yes, entirely.

However the code *you* write in your `then`s might not be!

Just make sure you don’t access state outside the chain from concurrent queues.
By default PromiseKit handlers run on the `main` thread, which is serial, so
typically you won't have to worry about this.

## Why are there separate classes for Objective-C and Swift?

`Promise<T>` is generic and and thus cannot be represented by Objective-C.

## Does PromiseKit conform to Promises/A+?

Yes, we have tests that prove this.

## How do PromiseKit and RxSwift differ?

https://github.com/mxcl/PromiseKit/issues/484

## Why can’t I return from a catch like I can in Javascript?

Swift demands functions with one purpose, thus we have two error handlers:

* `catch`: ends the chain and handles errors
* `recover`: attempts to recover from errors in a chain

You want `recover`.

## When do promises “start”?

Often people are confused about when Promises “start”. Is it immediately? Is it
later? Is it when you call then?

The answer is: promises do not choose when the underlying task they represent
starts. That is up to that task. For example here is the code for a simple
promise that wraps Alamofire:


```swift
func foo() -> Promise<Any>
    return Promise { fulfill, reject in
        Alamofire.request(rq).responseJSON { rsp in
            if let error = rsp.error {
                reject(error)
            } else {
                fulfill(rsp.value)
            }
        }
    }
}
```

Who chooses when this promise starts? The answer is: Alamofire does and in this
case, it “starts” immediately when `foo()` is called.

## My question was not answered

[Please open a ticket](https://github.com/mxcl/PromiseKit/issues/new).
