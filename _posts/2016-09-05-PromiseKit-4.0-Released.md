---
layout: default
title: PromiseKit 4.0 Released
---

# PromiseKit 4.0 Released!

Swift 3 comes with breaking API changes, so PromiseKit also had to have breaking major semantic version changes. Hence we are releasing version 4.

As has become tradition now, we also took the opportunity to improve the library.

As a result we also provide a `swift-2.3-minimal-changes` branch, which is PromiseKit 2 but ported to Swift 2.3, whih is also provided by Xcode 8.

## Notable Changes

### Minimum Deployment Target

* PromiseKit now requires a deployment target >= macOS 10.10, the deployment targets for iOS, watchOS and tvOS are unchanged.

### `catch` Returns

* Swift 3 now allows keywords to be used as member functions, so thankfully we have restored `catch`.

### Initializer Changes

* We have moved all initializers except `Promise { fulfill, reject in }` to class methods to prevent ambiguity in usage and make the compiler happy for the 90% use case.

### `recover` Behavior Change
* `recover` now takes a `CatchPolicy` which means it **by default** no longer “catches” cancellation errors, you should vet any use of `recover`. Probably this is actually what you wanted all along.

### `@import PromiseKit;` works

* You can now `@import PromiseKit;`, before this wouldn’t import the whole library in an effort to prevent Swift and ObjC seeing the parts of PromiseKit designed for the other. We now properly use `NS_REFINED_FOR_SWIFT` et al. and thus the build-system manages symbol visibility for us.

### `Error.when` Removed

https://github.com/mxcl/PromiseKit/issues/341

### `join()` Behavior Change

Your old joins won't compile, so you’ll notice this change for sure.

### Unused Return Value Warning

`then` will warn if you don't use the promise it returns. This is because it is typically a bug to not use the promise and indicates an unterminated promise chain.

> All chains should terminate at a `catch` handler or be returned from a function that will then terminate the chain at a `catch` handler.

However ocassionally it is legitimate to not terminate a chain, in such cases you can hide the warning by making it clear to the compiler that you are happy to ignore the result:

```swift
_ = foo.then{ /*…*/ }
```

### `AnyPromise -finally`

Renamed always so as to be consistent with `Promise<T>`, and because `finally` was not a good metaphor for promises relative to the `try`, `catch`, `finally` objc exception pattern we were originally partially emulating with PMK1.

### OMGHTTPURLRQ / Alamofire

OMGHTTPURLRQ is no longer a dependency of the `Foundation` extensions, instead it is now its own subspec: https://github.com/PromiseKit/OMGHTTPURLRQ

An Alamofire extension was added: https://github.com/PromiseKit/Alamofire

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

## PromiseKit Organization

PromiseKit extensions are now grouped at the PromiseKit GitHub organization to facilitate better testing, easier contribution and more sensible responsibility divisions.
