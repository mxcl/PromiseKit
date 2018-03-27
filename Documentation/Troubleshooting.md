# Troubleshooting

## Compile Errors

99% of questions about compile issues with PromiseKit can be solved by either:

### 0. Check Your Handler

```swift
return firstly {
      URLSession.shared.dataTask(.promise, with: url)
}.compactMap {
    JSONSerialization.jsonObject(with: $0.data) as? [String: Any]
}.then { dict in
    User(dict: dict)
}
```

Swift (unhelpfully) says:

> Cannot convert value of type '([String : Any]) -> User' to expected argument type '([String : Any]) -> _'

What’s the real problem? `then` *must* return a `Promise`, you wanted `map`:

```swift
return firstly {
      URLSession.shared.dataTask(.promise, with: url)
}.compactMap {
    JSONSerialization.jsonObject(with: $0.data) as? [String: Any]
}.map { dict in
    User(dict: dict)
}
```

### 1. Specifying Closure Parameters **and** Return Types

Please try it.

We made great effort to reduce the need for this with PromiseKit 6, but like
normal functions in Swift (eg. Array.map) that return a generic type, if the
closure body is longer than one line you may need to tell Swift what returns.

> Tip: Sometimes you can force a one liner with semi-colons.

For example:

```swift
func _() -> Promise<Void> {
    return firstly {
        proc.launch(.promise)      // proc: Foundation.Process
    }.then {
        when(fulfilled: p1, p2)    // both p1 & p2 are `Promise<Void>`
    }
}
```

Fails to compile with: 

    Cannot invoke 'then' with an argument list of type '(() -> _)
  
Highlighting the `then`. The fix is to specify the closure parameter of the
`then`:

```swift
func _() -> Promise<Void> {
    return firstly {
        proc.launch(.promise)
    }.then { _ in
        when(fulfilled: p1, p2)
    }
}
```

Why is this the fix? Well `Process.launch(.promise)` returns
`Promise<(String, String)>` and we were ignoring this value in our `then`, if
we’d used `$0` or named the parameter we’d be fine.

Swift’s diagnostics were unhelpful at every stage trying to troubleshoot this
example. You’re on your own :(

### 2. Move Code To A Temporary Inline Function

Take the code out of the closure and put it in a standalone function, now Swift
will tell you the *real* error message. For example:

```swift
func doStuff() {
    firstly {
        foo()
    }.then {
        let bar = bar()
        let baz = baz()
        when(fulfilled: bar, baz)
    }
}
```

Becomes:

```swift
func doStuff() {
    func fluff() -> Promise<…> {
        let bar = bar()
        let baz = baz()
        when(fulfilled: bar, baz)  
    }

    firstly {
        foo()
    }.then {
        fluff()
    }
}
```

So an *inline* function is all you need. Now Swift will tell you the real
error message. Here that you forgot a `return`.

## You Copied Code Off The Internet That Doesn’t Work

Swift changed a lot over the years and thus PromiseKit has had to change to keep
up. Your code is probably for an older PromiseKit. *Read the definitions of the
functions*. Doing this with Xcode is easy (option click or command click). All
PromiseKit functions are documented and provide examples.

## Context type for closure argument expects 1 argument, which cannot be implicitly ignored

You have a `then` you want a `done`.

## Other Issues

### `Pending Promise Deallocated!`

If you see this warning you have a path in your `Promise` initializer where the
promise is not sealed:

```swift
Promise<String> { seal in
    task { value, error in
        if let value = value as? String {
            seal.fulfill(value)
        } else if let error = error {
            seal.reject(error)
        }
    }
}
```

There are two missing paths here and if either occur the promise will soon be
deallocated without resolving. This will show itself as a bug in your app,
probably the awful: infinite spinner.

So let’s be thorough:

```swift
Promise<String> { seal in
    task { value, error in
        if let value = value as? String {
            fulfill(value)
        } else if let error = error {
            reject(error)
        } else if value != nil {
            reject(MyError.valueNotString)
        } else {
            // should never happen, but we have an `PMKError` for task being called with `nil`, `nil`
            reject(PMKError.invalidCallingConvention)
        }
    }
}
```

If this seems tedious it shouldn’t. You would have to be this thorough withoutpromises too, the difference is without promises you wouldn’t get a warning in the console letting you know your mistake!

### Slow Compilation / Compiler Cannot Solve in Reasonable Time

Add return types to your closures.

### My Promise Never Resolves

Check your asynchronous task even *starts*. You’d be surprised how often this is
the cause. For example if you are using `URLSession` (without our extension, but
don’t do that, *use* our extension, it’s thorough) did you forget to call
`resume` on the task? If so it never starts, so of course, it never finishes
either.

### `Result of call to 'foo(on:_:)' is unused`

Promise deliberately avoids the `@discardableResult` annotation because the
unused result warning is your hint that you have not handled the error in your
chain. So do one of these:

1. Add a `catch`
2. `return` the promise (thus punting the error handling to the caller)
3. Use `cauterize()` to silence the warning.

Obviously do 1. or 2. in preference to 3.
