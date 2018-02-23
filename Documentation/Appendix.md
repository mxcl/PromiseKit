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

## Background loaded member variables

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

It is often convenient to erase the type of a promise to facilitate chaining,
for example `UIView.animate(.promise)` returns `Guarantee<Bool>` since UIKit’s
completion feeds `Bool`, however we usually don’t need it and we can chain
more simply if it were `Void`, thus we use `asVoid()`:

```swift
UIView.animate(.promise, duration: 0.3) {
    self.button1.alpha = 0
}.asVoid().done(self.nextStep)
```

For situations where we are combining many promises into a `when`, `asVoid()`
becomes essential:

```swift
let p1 = foo()
let p2 = bar()
let p3 = baz()
//…
let p10 = fluff()

when(fulfilled: p1, p2, p3, /*…*/, p10).then {
    let value1 = foo().value!  // safe bang since all the promises fulfilled
    // …
    let value10 = fluff().value!
}.catch {
    //…
}
```

Note the reason you don’t have to do this usually with `when` is we do this *for
you* for `when`s with up to 5 parameters.
