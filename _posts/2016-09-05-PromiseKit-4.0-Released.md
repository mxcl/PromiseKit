---
layout: default
title: PromiseKit 4.0 Released
---

# PromiseKit 4.0 Released!

Swift 3 breaks its API, so to support Swift 3 it was mandatory to bump PromiseKit to version 4. Consequently we took the opportunity to improve the library — though we provide a `swift-2.3-minimal-changes` branch, which is PromiseKit 2 but ported to Swift 2.3 (also part of Xcode 8) to aid migrations.

## Notable Changes

### Minimum Deployment Target

PromiseKit now requires a deployment target >= macOS 10.10, the deployment targets for iOS, watchOS and tvOS are unchanged (8.0, 2.0 and 9.0 respectfully).

### `catch` is back

* Swift 3 allows keywords to be used as member functions, so thankfully we have restored `catch`.
* `catch` also returns `self` so that you can chain off of `catch`, this is not the same behavior as `AnyPromise`’s `catch` which behaves like `Promise<T>`’s `recover`.

### `PromiseKit.wrap`

To remove initializer ambiguity, improve error messages and to allow generic specializations we have moved our convenience initializers that wrap traditional Cocoa asynchronous patterns to a free-standing function: `wrap`:

```swift
func foo() -> Promise<Foo> {
    let bar = Bar(conf: /*…*/)
    return PromiseKit.wrap(bar.start)
}
```

### `recover` Behavior Change

`recover` now takes a `CatchPolicy` which means it **by default** no longer “catches” cancellation errors, you should vet any use of `recover`. Probably this is actually what you wanted all along.

### `@import PromiseKit;` works

You can now `@import PromiseKit;`, before this wouldn’t import the whole library in an effort to prevent Swift and ObjC seeing the parts of PromiseKit designed for the other. We now properly use `NS_REFINED_FOR_SWIFT` et al. and thus the build-system manages symbol visibility for us.

### `Error.when` Removed

See: [https://github.com/mxcl/PromiseKit/issues/341](https://github.com/mxcl/PromiseKit/issues/341).

### `join()` Behavior Change

`join` has been deprecated and replaced with `when(resolved:)` (standard `when` is now `when(fulfilled:)`). This promise never rejects and instead always fulfills with an array of `Result<T>`.

### Unused Return Value Warning

`then` will warn if you don't use the promise it returns. This is because it is typically a bug to not use the promise and indicates an unterminated promise chain.

> All chains should terminate at a `catch` handler or be returned from a function that will then terminate the chain at a `catch` handler.

However ocassionally it is legitimate to not terminate a chain, in such cases you can hide the warning by making it clear to the compiler that you are happy to ignore the result:

```swift
_ = foo.then{ /*…*/ }
```

### `AnyPromise -finally`

Renamed `always` so as to be consistent with `Promise<T>`, and because `finally` was not a good metaphor for promises relative to the `try`, `catch`, `finally` objc exception pattern we were originally partially emulating with PMK1.

### OMGHTTPURLRQ / Alamofire

OMGHTTPURLRQ is no longer a dependency of the `Foundation` extensions, instead it is now its own subspec: [https://github.com/PromiseKit/OMGHTTPURLRQ](https://github.com/PromiseKit/OMGHTTPURLRQ)

An Alamofire extension was added: [https://github.com/PromiseKit/Alamofire](https://github.com/PromiseKit/Alamofire).

So from now on you should choose one of the two to handle the parts of HTTP networking that Apple left out:

```ruby
# CocoaPods
pod "PromiseKit/Alamofire", "~> 1.0"     # pick
pod "PromiseKit/OMGHTTPURLRQ", "~> 1.0"  # one

# Carthage
github "PromiseKit/Alamofire" ~> 1.0     # pick
github "PromiseKit/OMGHTTPURLRQ" ~> 1.0  # one
```

The default podspec *no longer* imports `OMGHTTPURLRQ`.

## New Features

* `PMKSetDefaultDispatchHandler`, you can set the default queue that all promises execute upon.
* `when(generator:concurrently)`, you can wait on all promises from a generator, promises are only created as required.

## Deprecated API Removed

PromiseKit no longer comes with `NSURLConnection`, `UIAlertView`, etc. extensions.

## The PromiseKit Organization

PromiseKit extensions are now grouped at the [PromiseKit GitHub organization](https://github.com/PromiseKit) to facilitate better testing, easier contribution and more sensible responsibility divisions.


# Gotchas

* `after()` becomes `after(interval: )` (mimicking Swift 3 API changes)
* `recover`, `then`, etc. no longer take a variable closure with no argument, that is `then(foo)` will now be: `then(execute: foo)`
* `thenInBackground` is deprecated, instead do `then(on: .global())`
* `error` is again `catch`