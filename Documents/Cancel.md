# Cancelling Promises

PromiseKit 7 adds clear and concise cancellation abilities to promises and to the [PromiseKit extensions](#extensions-pane).  Cancelling promises and their associated tasks is now simple and straightforward.  Promises and promise chains can safely and efficiently be cancelled from any thread at any time.

```swift
UIApplication.shared.isNetworkActivityIndicatorVisible = true

let fetchImage = URLSession.shared.dataTask(.promise, with: url).cancellize().compactMap{ UIImage(data: $0.data) }
let fetchLocation = CLLocationManager.requestLocation().cancellize().lastValue

let finalizer = firstly {
    when(fulfilled: fetchImage, fetchLocation)
}.done { image, location in
    self.imageView.image = image
    self.label.text = "\(location)"
}.ensure {
    UIApplication.shared.isNetworkActivityIndicatorVisible = false
}.catch(policy: .allErrors) { error in
    /* 'catch' will be invoked with 'PMKError.cancelled' when cancel is called on the context.
       Use the default policy of '.allErrorsExceptCancellation' to ignore cancellation errors. */
    self.show(UIAlertController(for: error), sender: self)
}

//…

// Cancel currently active tasks and reject all cancellable promises with 'PMKError.cancelled'.
// 'cancel()' can be called from any thread at any time.
finalizer.cancel()

/* 'finalizer' here refers to the 'CancellableFinalizer' for the chain.  Calling 'cancel' on
   any promise in the chain or on the finalizer cancels the entire chain.  Therefore
   calling 'cancel' on the finalizer cancels everything. */
```

# Cancel Chains

Promises can be cancelled using a `CancellablePromise`.  The `cancellize()` method on `Promise` is used to convert a `Promise` into a `CancellablePromise`.  If a promise chain is initialized with a `CancellablePromise`, then the entire chain is cancellable.  Calling `cancel()` on any promise in the chain cancels the entire chain.  

Creating a chain where the entire chain can be cancelled is the recommended usage for cancellable promises.

The `CancellablePromise` contains a `CancelContext` that keeps track of the tasks and promises for the chain.  Promise chains can be cancelled either by calling the `cancel()` method on any `CancellablePromise` in the chain, or by calling `cancel()` on the `CancelContext` for the chain. It may be desirable to hold on to the `CancelContext` directly rather than a promise so that the promise can be deallocated by ARC when it is resolved.

For example:

```swift
let context = firstly {
    login()
    /* The 'Thenable.cancellize' method initiates a cancellable promise chain by
       returning a 'CancellablePromise'. */
}.cancellize().then { creds in
    fetch(avatar: creds.user)
}.done { image in
    self.imageView = image
}.catch(policy: .allErrors) { error in
    if error.isCancelled {
        // the chain has been cancelled!
    }
}.cancelContext

// …

/* Note: Promises can be cancelled using the 'cancel()' method on the 'CancellablePromise'.
   However, it may be desirable to hold on to the 'CancelContext' directly rather than a
   promise so that the promise can be deallocated by ARC when it is resolved. */
context.cancel()
```

### Creating a partially cancellable chain

A `CancellablePromise` can be placed at the start of a chain, but it cannot be embedded directly in the middle of a standard (non-cancellable) promise chain.  Instead, a partially cancellable promise chain can be used.  A partially cancellable chain is not the recommended way to use cancellable promises, although there may be cases where this is useful.

**Convert a cancellable chain to a standard chain**

`CancellablePromise` wraps a delegate `Promise`, which can be accessed with the `promise` property.  The above example can be modified as follows so that once `login()` completes, the chain can no longer be cancelled:

```swift
/* Here, by calling 'promise.then' rather than 'then' the chain is converted from a cancellable
   promise chain to a standard promise chain. In this example, calling 'cancel()' during 'login'
   will cancel the chain but calling 'cancel()' during the 'fetch' operation will have no effect: */
let cancellablePromise = firstly {
    login().cancellize()
}
cancellablePromise.promise.then {
    fetch(avatar: creds.user)      
}.done { image in
    self.imageView = image
}.catch(policy: .allErrors) { error in
    if error.isCancelled {
        // the chain has been cancelled!
    }
}

// …

/* This will cancel the 'login' but will not cancel the 'fetch'.  So whether or not the
   chain is cancelled depends on how far the chain has progressed. */
cancellablePromise.cancel()
```

**Convert a standard chain to a cancellable chain**

A non-cancellable chain can be converted to a cancellable chain in the middle of the chain as follows:

```swift
/* In this example, calling 'cancel()' during 'login' will not cancel the login.  However,
   the chain will be cancelled immediately, and the 'fetch' will not be executed.  If 'cancel()'
   is called during the 'fetch' then both the 'fetch' itself and the promise chain will be
   cancelled immediately. */
let promise = firstly {
    login()
}.then {
    fetch(avatar: creds.user).cancellize()
}.done { image in
    self.imageView = image
}.catch(policy: .allErrors) { error in
    if error.isCancelled {
        // the chain has been cancelled!
    }
}

// …

promise.cancel()
```

# Core Cancellable PromiseKit API

The following classes, methods and functions have been added to PromiseKit to support cancellation. Existing functions or methods with underlying tasks that can be cancelled are indicated by being appended with '.cancellize()'.

<pre><code><b>Thenable</b>
    cancellize(_:)                 - Converts the Promise or Guarantee (Thenable) into a
                                     CancellablePromise, which is a cancellable variant of the given
                                     Promise or Guarantee (Thenable)

<b>Global functions</b>
    after(seconds:).<mark><b>cancellize()</b></mark>   - 'after' with seconds can be cancelled
    after(_:).<mark><b>cancellize</b></mark>           - 'after' with interval can be cancelled

    firstly(execute:)               - Accepts body returning Promise or CancellablePromise
    hang(_:)                        - Accepts Promise and CancellablePromise
    race(_:)                        - Accepts [Promise] and [CancellablePromise]
    when(fulfilled:)                - Accepts [Promise] and [CancellablePromise]
    when(fulfilled:concurrently:)   - Accepts iterator of type Promise or CancellablePromise
    when(resolved:)                 - Accepts [Promise] and [CancellablePromise]

<b>CancellablePromise properties and methods</b>
    promise                         - Delegate Promise for this CancellablePromise
    result                          - The current Result

    init(_ bridge:<span style="color:gray;"><i>cancelContext</i>:</span>)   - Initialize a new cancellable promise bound to the provided Thenable
    init(<span style="color:gray;"><i>cancellable</i>:</span>resolver body:).  - Initialize a new cancellable promise that can be resolved with
                                       the provided '(Resolver) throws -> Void' body
    init(<span style="color:gray;"><i>cancellable</i>:</span>promise:resolver:)  - Initialize a new cancellable promise using the given Promise
                                       and its Resolver
    init(<span style="color:gray;"><i>cancellable</i>:</span>error:)          - Initialize a new rejected cancellable promise
    init(<span style="color:gray;"><i>cancellable</i>:</span>)                - Initializes a new cancellable promise fulfilled with Void

    pending() -> (promise:resolver:)  - Returns a tuple of a new cancellable pending promise and its
                                        Resolver

<b>CancellableThenable properties and methods</b>
    thenable                        - Delegate Thenable for this CancellableThenable

    cancel(<span style="color:gray;"><i>error</i>:</span>)                  - Cancels all members of the promise chain
    cancelContext                   - The CancelContext associated with this CancellableThenable
    cancelItemList                  - Tracks the cancel items for this CancellableThenable
    isCancelled                     - True if all members of the promise chain have been successfully
                                      cancelled, false otherwise
    cancelAttempted                 - True if 'cancel' has been called on the promise chain associated
                                      with this CancellableThenable, false otherwise
    cancelledError                  - The error generated when the promise is cancelled
    appendCancellable(cancellable:<span style="color:gray;"><i>reject</i>:</span>)  - Append the Cancellable task to our cancel context
    appendCancelContext(from:)      - Append the cancel context associated with 'from' to our
                                      CancelContext

    then(<span style="color:gray;"><i>on</i>:</span><span style="color:gray;"><i>flags</i>:</span>_ body:)           - Accepts body returning CancellableThenable
    cancellableThen(<span style="color:gray;"><i>on</i>:</span><span style="color:gray;"><i>flags</i>:</span>_ body:)  - Accepts body returning Thenable
    map(<span style="color:gray;"><i>on</i>:</span><span style="color:gray;"><i>flags</i>:</span>_ transform:)
    compactMap(<span style="color:gray;"><i>on</i>:</span><span style="color:gray;"><i>flags</i>:</span>_ transform:)
    done(<span style="color:gray;"><i>on</i>:</span><span style="color:gray;"><i>flags</i>:</span>_ body:)
    get(<span style="color:gray;"><i>on</i>:</span><span style="color:gray;"><i>flags</i>:</span>_ body:)
    tap(<span style="color:gray;"><i>on</i>:</span><span style="color:gray;"><i>flags</i>:</span>_ body:)
    asVoid()

    error
    isPending
    isResolved
    isFulfilled
    isRejected
    value

    mapValues(<span style="color:gray;"><i>on</i>:</span><span style="color:gray;"><i>flags</i>:</span>_ transform:)
    flatMapValues(<span style="color:gray;"><i>on</i>:</span><span style="color:gray;"><i>flags</i>:</span>_ transform:)
    compactMapValues(<span style="color:gray;"><i>on</i>:</span><span style="color:gray;"><i>flags</i>:</span>_ transform:)
    thenMap(<span style="color:gray;"><i>on</i>:</span><span style="color:gray;"><i>flags</i>:</span>_ transform:)                 - Accepts transform returning CancellableThenable
    cancellableThenMap(<span style="color:gray;"><i>on</i>:</span><span style="color:gray;"><i>flags</i>:</span>_ transform:)      - Accepts transform returning Thenable
    thenFlatMap(<span style="color:gray;"><i>on</i>:</span><span style="color:gray;"><i>flags</i>:</span>_ transform:)             - Accepts transform returning CancellableThenable
    cancellableThenFlatMap(<span style="color:gray;"><i>on</i>:</span><span style="color:gray;"><i>flags</i>:</span>_ transform:)  - Accepts transform returning Thenable
    filterValues(<span style="color:gray;"><i>on</i>:</span><span style="color:gray;"><i>flags</i>:</span>_ isIncluded:)
    firstValue
    lastValue
    sortedValues(<span style="color:gray;"><i>on</i>:</span><span style="color:gray;"><i>flags</i>:</span>)

<b>CancellableCatchable properties and methods</b>
    catchable                                      - Delegate Catchable for this CancellableCatchable
    catch(<span style="color:gray;"><i>on</i>:</span><span style="color:gray;"><i>flags</i>:</span><span style="color:gray;"><i>policy</i>:</span>:_ body:)                - Accepts body returning Void
    recover(<span style="color:gray;"><i>on</i>:</span><span style="color:gray;"><i>flags</i>:</span><span style="color:gray;"><i>policy</i>:</span>:_ body:)              - Accepts body returning CancellableThenable
    cancellableRecover(<span style="color:gray;"><i>on</i>:</span><span style="color:gray;"><i>flags</i>:</span><span style="color:gray;"><i>policy</i>:</span>:_ body:)   - Accepts body returning Thenable
    ensure(<span style="color:gray;"><i>on</i>:</span><span style="color:gray;"><i>flags</i>:</span>_ body:)                       - Accepts body returning Void
    ensureThen(<span style="color:gray;"><i>on</i>:</span><span style="color:gray;"><i>flags</i>:</span>_ body:)                   - Accepts body returning CancellablePromise
    finally(_ body:)
    cauterize()
</code></pre>

# <a name="extensions-pane"></a> Extensions

Cancellation support has been added to the PromiseKit extensions, but only where the underlying asynchronous tasks can be cancelled. This example Podfile lists the PromiseKit extensions that support cancellation along with a usage example:

<pre><code>pod "PromiseKit/Alamofire"
# Alamofire.request("http://example.com", method: .get).responseDecodable(DecodableObject.self).<mark><b>cancellize</b></mark>()

pod "PromiseKit/Bolts"
# CancellablePromise(…).then() { _ -> BFTask<NSString> in /*…*/ }  // Returns <mark><b>CancellablePromise</b></mark>

pod "PromiseKit/CoreLocation"
# CLLocationManager.requestLocation().<mark><b>cancellize</b></mark>().then { /*…*/ }

pod "PromiseKit/Foundation"
# URLSession.shared.dataTask(.promise, with: request).<mark><b>cancellize</b></mark>().then { /*…*/ }

pod "PromiseKit/MapKit"
# MKDirections(…).calculate().<mark><b>cancellize</b></mark>().then { /*…*/ }

pod "PromiseKit/OMGHTTPURLRQ"
# URLSession.shared.GET("http://example.com").<mark><b>cancellize</b></mark>().then { /*…*/ }

pod "PromiseKit/StoreKit"
# SKProductsRequest(…).start(.promise).<mark><b>cancellize</b></mark>().then { /*…*/ }

pod "PromiseKit/SystemConfiguration"
# SCNetworkReachability.promise().<mark><b>cancellize</b></mark>().then { /*…*/ }

pod "PromiseKit/UIKit"
# UIViewPropertyAnimator(…).startAnimation(.promise).<mark><b>cancellize</b></mark>().then { /*…*/ }
</code></pre>

Here is a complete list of PromiseKit extension methods that support cancellation:

[Alamofire](http://github.com/PromiseKit/Alamofire-)

<pre><code>Alamofire.DataRequest
    response(_:<span style="color:gray;"><i>queue</i>:</span>).<mark><b>cancellize</b></mark>()
    responseData(<span style="color:gray;"><i>queue</i>:</span>).<mark><b>cancellize</b></mark>()
    responseString(<span style="color:gray;"><i>queue</i>:</span>).<mark><b>cancellize</b></mark>()
    responseJSON(<span style="color:gray;"><i>queue</i>:</span><span style="color:gray;"><i>options</i>:</span>).<mark><b>cancellize</b></mark>()
    responsePropertyList(<span style="color:gray;"><i>queue</i>:</span><span style="color:gray;"><i>options</i>:</span>).<mark><b>cancellize</b></mark>()
    responseDecodable<T>(<span style="color:gray;"><i>queue</i>:</span>:<span style="color:gray;"><i>decoder</i>:</span>).<mark><b>cancellize</b></mark>()
    responseDecodable<T>(_ type:<span style="color:gray;"><i>queue</i>:</span><span style="color:gray;"><i>decoder</i>:</span>).<mark><b>cancellize</b></mark>()

Alamofire.DownloadRequest
    response(_:<span style="color:gray;"><i>queue</i>:</span>).<mark><b>cancellize</b></mark>()
    responseData(<span style="color:gray;"><i>queue</i>:</span>).<mark><b>cancellize</b></mark>()
</code></pre>

[Bolts](http://github.com/PromiseKit/Bolts)

<pre><code><mark><b>CancellablePromise</b></mark>&lt;T&gt;
    then&lt;U&gt;(<span style="color:gray;"><i>on: DispatchQueue?</i></span>, body: (T) -> BFTask&lt;U&gt;) -> <mark><b>CancellablePromise</b></mark><U?>
</code></pre>

[CoreLocation](http://github.com/PromiseKit/CoreLocation)

<pre><code>CLLocationManager
    requestLocation(<span style="color:gray;"><i>authorizationType</i>:</span><span style="color:gray;"><i>satisfying</i>:</span>).<mark><b>cancellize</b></mark>()
    requestAuthorization(<span style="color:gray;"><i>type requestedAuthorizationType</i>:</span>).<mark><b>cancellize</b></mark>()
</code></pre>

[Foundation](http://github.com/PromiseKit/Foundation)

<pre><code>NotificationCenter:
    observe(<span style="color:gray;"><i>once:object:</i></span>).<mark><b>cancellize</b></mark>()

NSObject
    observe(_:keyPath:).<mark><b>cancellize</b></mark>()

Process
    launch(_:).<mark><b>cancellize</b></mark>()

URLSession
    dataTask(_:with:).<mark><b>cancellize</b></mark>()
    uploadTask(_:with:from:).<mark><b>cancellize</b></mark>()
    uploadTask(_:with:fromFile:).<mark><b>cancellize</b></mark>()
    downloadTask(_:with:to:).<mark><b>cancellize</b></mark>()

<mark><b>CancellablePromise</b></mark>
    validate()
</code></pre>

[HomeKit](http://github.com/PromiseKit/HomeKit)  

<pre><code>HMPromiseAccessoryBrowser
    start(scanInterval:).<mark><b>cancellize</b></mark>()

HMHomeManager
    homes().<mark><b>cancellize</b></mark>()
</code></pre>

[MapKit](http://github.com/PromiseKit/MapKit)  

<pre><code>MKDirections
    calculate().<mark><b>cancellize</b></mark>()
    calculateETA().<mark><b>cancellize</b></mark>()

MKMapSnapshotter
    start().<mark><b>cancellize</b></mark>()
</code></pre>

[StoreKit](http://github.com/PromiseKit/StoreKit)  

<pre><code>SKProductsRequest
    start(_:).<mark><b>cancellize</b></mark>()

SKReceiptRefreshRequest
    promise().<mark><b>cancellize</b></mark>()
</code></pre>

[SystemConfiguration](http://github.com/PromiseKit/SystemConfiguration)

<pre><code>SCNetworkReachability
    promise().<mark><b>cancellize</b></mark>()
</code></pre>

[UIKit](http://github.com/PromiseKit/UIKit)  

<pre><code>UIViewPropertyAnimator
    startAnimation(_:).<mark><b>cancellize</b></mark>()
</code></pre>

## Choose Your Networking Library

All the networking library extensions supported by PromiseKit are now simple to cancel!

[Alamofire](http://github.com/PromiseKit/Alamofire-)

```swift
// pod 'PromiseKit/Alamofire'
// # https://github.com/PromiseKit/Alamofire

let context = firstly {
    Alamofire
        .request("http://example.com", method: .post, parameters: params)
        .responseDecodable(Foo.self)
}.cancellize().done { foo in
    //…
}.catch { error in
    //…
}.cancelContext

//…

context.cancel()
```

And (of course) plain `URLSession` from [Foundation](http://github.com/PromiseKit/Foundation):

```swift
// pod 'PromiseKit/Foundation'
// # https://github.com/PromiseKit/Foundation

let context = firstly {
    URLSession.shared.dataTask(.promise, with: try makeUrlRequest())
}.cancellize().map {
    try JSONDecoder().decode(Foo.self, with: $0.data)
}.done { foo in
    //…
}.catch { error in
    //…
}.cancelContext

//…

context.cancel()

func makeUrlRequest() throws -> URLRequest {
    var rq = URLRequest(url: url)
    rq.httpMethod = "POST"
    rq.addValue("application/json", forHTTPHeaderField: "Content-Type")
    rq.addValue("application/json", forHTTPHeaderField: "Accept")
    rq.httpBody = try JSONSerialization.jsonData(with: obj)
    return rq
}
```

# Cancellability Goals

* Provide a streamlined way to cancel a promise chain, which rejects all associated promises and cancels all associated tasks. For example:

```swift
let promise = firstly {
    login()
}.cancellize().then { creds in // Use the 'cancellize' function to initiate a cancellable promise chain
    fetch(avatar: creds.user)
}.done { image in
    self.imageView = image
}.catch(policy: .allErrors) { error in
    if error.isCancelled {
        // the chain has been cancelled!
    }
}
//…
promise.cancel()
```

* Ensure that subsequent code blocks in a promise chain are _never_ called after the chain has been cancelled

* Fully support concurrency, where all code is thread-safe.  Cancellable promises and promise chains can safely and efficiently be cancelled from any thread at any time.

* Provide cancellable support for all PromiseKit extensions whose native tasks can be cancelled (e.g. Alamofire, Bolts, CoreLocation, Foundation, HealthKit, HomeKit, MapKit, StoreKit, SystemConfiguration, UIKit)

* Support cancellation for all PromiseKit primitives such as 'after', 'firstly', 'when', 'race'

* Provide a simple way to make new types of cancellable promises

* Ensure promise branches are properly cancelled.  For example:

```swift
import Alamofire
import PromiseKit

func updateWeather(forCity searchName: String) {
    refreshButton.startAnimating()
    let context = firstly {
        getForecast(forCity: searchName)
    }.cancellize().done { response in
        updateUI(forecast: response)
    }.ensure {
        refreshButton.stopAnimating()
    }.catch { error in
        // Cancellation errors are ignored by default
        showAlert(error: error)
    }.cancelContext

    //…

    /* **** Cancels EVERYTHING (except... the 'ensure' block always executes regardless)    
       Note: non-cancellable tasks cannot be interrupted.  For example: if 'cancel()' is
       called in the middle of 'updateUI()' then the chain will immediately be rejected,
       however the 'updateUI' call will complete normally because it is not cancellable.
       Its return value (if any) will be discarded. */
    context.cancel()
}

func getForecast(forCity name: String) -> CancellablePromise<WeatherInfo> {
    return firstly {
        Alamofire.request("https://autocomplete.weather.com/\(name)")
            .responseDecodable(AutoCompleteCity.self)
    }.cancellize().then { city in
        Alamofire.request("https://forecast.weather.com/\(city.name)")
            .responseDecodable(WeatherResponse.self).cancellize()
    }.map { response in
        format(response)
    }
}
```
