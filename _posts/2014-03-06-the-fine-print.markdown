---
category: home
layout: default
---

# The Fine Print

The fine print of PromiseKit is mostly exactly what you would expect, so don’t confuse yourself: only come back here when you find yourself curious about more advanced techniques.

* Returning a Promise as the value of a `then` (or `catch`) handler will cause any subsequent handlers to wait for that Promise to resolve.
* Returning an instance of `NSError` or throwing an exception within a then block will cause PromiseKit to bubble that object up to the *next* nearest catch handler.
* `catch` handlers are *always* passed an `NSError` object.
* `then` handlers that follow `catch` handlers **will** execute. So if your `catch` handler returns nothing, the next `then` will execute with `nil` as its parameter.
* Returning an `NSError` (or `@throw`ing) from a `catch` will “throw” to the next catch.
* Returning a non-error value from a `catch` will pass that value to the next `then`
* Nothing happens if you add a `then` to a failed Promise (unless you subsequently add a `catch` handler to the Promise returned from that `then`)


# Promises/A+ Compliance

PromiseKit is [compliant](http://promisesaplus.com) excluding:

* Our `then` does not take a failure handler, instead we have a dedicated `catch`
* Returning an `NSError *` from a `then` or `catch` rejects the returned `Promise`, strictly the specification dictates that only throwing should reject a promise.
* Strictly you should be able to fulfill a Promise with any object, however we do not allow you to fulfill a Promise with an `NSError` object. If you do, the Promise is rejected.

If you find further non-compliance please open a [ticket](https://github.com/mxcl/PromiseKit/issues/new).


## Beyond Promises/A+

* Promises can be fulfilled with multiple arguments which are then passed to the next `then`
* We offer a `when`/`all`
* We offer an `until`
