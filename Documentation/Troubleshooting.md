# Troubleshooting

## Compilation errors

99% of compilation issues involving PromiseKit can be addressed or diagnosed by one of the fixes below.

### Check your handler

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

What’s the real problem? `then` *must* return a `Promise`, and you're trying to return something else. What you really want is `map`:

```swift
return firstly {
      URLSession.shared.dataTask(.promise, with: url)
}.compactMap {
    JSONSerialization.jsonObject(with: $0.data) as? [String: Any]
}.map { dict in
    User(dict: dict)
}
```

### Specify closure parameters **and** return type

For example:

```swift
return firstly {
    foo()
}.then { user in
    //…
    return bar()
}
```

This code may compile if you specify the type of `user`:


```swift
return firstly {
    foo()
}.then { (user: User) in
    //…
    return bar()
}
```

If it still doesn't compile, perhaps you need to specify the return type, too:

```swift
return firstly {
    foo()
}.then { (user: User) -> Promise<Bar> in
    //…
    return bar()
}
```

We have made great effort to reduce the need for explicit typing in PromiseKit 6, 
but as with all Swift functions that return a generic type (e.g., `Array.map`),
you may need to explicitly tell Swift what a closure returns if the closure's body is
longer than one line.

> *Tip*: Sometimes you can force a one-liner by using semicolons.


### Acknowledge all incoming closure parameters

Swift does not permit you to silently ignore a closure's parameters. For example, this code:

```swift
func _() -> Promise<Void> {
    return firstly {
        proc.launch(.promise)      // proc: Foundation.Process
    }.then {
        when(fulfilled: p1, p2)    // both p1 & p2 are `Promise<Void>`
    }
}
```

Fails to compile with the error:

    Cannot invoke 'then' with an argument list of type '(() -> _)
  
What's the problem? Well, `Process.launch(.promise)` returns
`Promise<(String, String)>`, and we are ignoring this value in our `then` closure. 
If we’d referenced `$0` or named the parameter, Swift would have been satisfied.

Assuming that we really do want to ignore the argument, the fix is to explicitly
acknowledge its existence by assigning it the name "_". That's Swift-ese for "I
know there's a value here, but I'm ignoring it."


```swift
func _() -> Promise<Void> {
    return firstly {
        proc.launch(.promise)
    }.then { _ in
        when(fulfilled: p1, p2)
    }
}
```

In this situation, you won't always receive an error message that's as clear as the
one shown above. Sometimes, a missing closure parameter sends Swift scurrying off
into type inference limbo. When it finally concludes that there's no way for it to make
all the inferred types work together, it may end up assigning blame to some other
closure entirely and giving you an error message that makes no sense at all.

When faced with this kind of enigmatic complaint, a good rule of thumb is to
double-check your argument and return types carefully. If everything looks OK, 
temporarily add explicit type information as shown above, just to rule
out misinference as a possible cause.

### Try moving code to a temporary inline function

Try taking the code out of a closure and putting it in a standalone function. Now Swift
will give you the *real* error message. For example:

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

An *inline* function like this is all you need. Here, the problem is that you
forgot to mark the last line of the closure with an explicit `return`. It's required
here because the closure is longer than one line.


## You copied code off the Internet that doesn’t work

Swift has changed a lot over the years and so PromiseKit has had to change to keep
up. The code you copied is probably for an older PromiseKit. *Read the definitions of the
functions.* It's easy to do this in Xcode by option-clicking or command-clicking function names.
All PromiseKit functions are documented and provide examples.

## "Context type for closure argument expects 1 argument, which cannot be implicitly ignored"

You have a `then`; you want a `done`.

## "Missing argument for parameter #1 in call"

This is part of Swift 4’s “tuplegate”.

You must specify your `Void` parameter:

```swift
seal.fulfill(())
```

Yes: we hope they revert this change in Swift 5 too.

## "Ambiguous reference to 'firstly(execute:)'"

Remove the firstly, e.g.:

```swift
firstly {
    foo()
}.then {
    //…
}
```

becomes: 

```swift
foo().then {
    //…
}
```

Rebuild and Swift should now tell you the *real* error.

## Other issues

### `Pending Promise Deallocated!`

If you see this warning, you have a path in your `Promise` initializer that allows
the promise to escape without being sealed:

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

There are two missing paths here, and if either occurs, the promise will soon be
deallocated without resolving. This will manifest itself as a bug in your app,
probably the awful infinite spinner.

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

If this seems tedious, it shouldn’t. You would have to be this thorough without promises, too.
The difference is that without promises, you wouldn’t get a warning in the console notifying
you of your mistake!

### Slow compilation / compiler cannot solve in reasonable time

Add return types to your closures.

### My promise never resolves

There are several potential causes:

#### 1. Check to be sure that your asynchronous task even *starts*

You’d be surprised how often this is the cause.

For example, if you are using `URLSession` without our extension (but
don’t do that; *use* our extension! we know all the pitfalls), did you forget
to call `resume` on the task? If so, the task never actually starts, and so of
course it never finishes, either.

#### 2. Check that all paths in your custom Promise initializers are handled

See “Pending Promise Deallocated” above. Usually you will see this warning if
you are not handling a path, but that requires your promise deallocate, so you
may not see this warning yet you are still not handling all paths.

Unhandled paths mean the promise will not resolve.

#### 3. Ensure the queue your promise handler runs upon is not blocked

If the thread is blocked the handlers cannot execute. Commonly you can see this
if you are using our `wait()` function. Please read the documentation for `wait()`
for suggestions and caveats.

### `Result of call to 'done(on:_:)' is unused`, `Result of call to 'then(on:_:)' is unused`

PromiseKit deliberately avoids the `@discardableResult` annotation because the
unused result warning is a hint that you have not handled the error in your
chain. So do one of these:

1. Add a `catch`
2. `return` the promise (thus punting the error handling to the caller)
3. Use `cauterize()` to silence the warning.

Obviously, do 1 or 2 in preference to 3.
