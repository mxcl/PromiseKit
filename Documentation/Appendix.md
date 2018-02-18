# Common Misusage

## Doubling Up Promises

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

Mostly when we see `Promise<Item?>` it implies a misuse of promises, for
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

The second `then` chooses to return `nil` in some circumstances. This imposes
the `nil` check on the consumer of this promise. Instead create an specific
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

# Background loaded member variables

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