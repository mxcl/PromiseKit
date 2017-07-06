# Common Misusage

## Doubling Up Promises

Don’t do this:

```swift
func toggleNetworkSpinnerWithPromise<T>(funcToCall: () -> Promise<T>) -> Promise<T> {
    return Promise { fulfill, reject in
        firstly {
            setNetworkActivityIndicatorVisible(true)
            return funcToCall()
        }.then { result in
            fulfill(result)
        }.always {
            setNetworkActivityIndicatorVisible(false)
        }.catch { err in
            reject(err)
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

Mostly when we see `Promise<Item?>` it implies a misuse of promises, for
example:

```swift
return firstly {
    getItems()
}.then { items -> Promise<[Item]?> in
    guard !items.isEmpty else {
        return Promise(value: nil)
    }
    return Promise(value: items)
}
```

The second `then` chooses to return `nil` in some circumstances. This imposes
the `nil` check on the consumer of this promise. Instead create an specific
error type for this condition:

```swift
return firstly {
    getItems()
}.then { items -> Promise<[Item]> in
    guard !items.isEmpty else {
        throw MyError.emptyItems
    }
    return items
}
```
