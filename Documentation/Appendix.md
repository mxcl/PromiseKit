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
        }.error { err in
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
