# Cancelling Promises

PromiseKit 7 adds clear and concise cancellation abilities to promises and to the [PromiseKit extensions](#extensions-pane).  Cancelling promises and their associated tasks is now simple and straightforward.

```swift
UIApplication.shared.isNetworkActivityIndicatorVisible = true

let fetchImage = cancellable(URLSession.shared.dataTask(.promise, with: url)).compactMap{ UIImage(data: $0.data) }
let fetchLocation = cancellable(CLLocationManager.requestLocation()).lastValue

let context = firstly {
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
}.cancelContext

//…

// Cancel currently active tasks and reject all cancellable promises with 'PMKError.cancelled'
context.cancel()

/* Note: Cancellable promises can be cancelled directly using the 'CancellablePromise.cancel()'
   method.  However by holding on to the 'CancelContext' rather than a cancellable promise, each
   promise in the chain can be deallocated by ARC as it is resolved. */
```

# Cancel Chains

Promises can be cancelled using a `CancellablePromise`.  The global `cancellable(_:)` function is used to convert a `Promise` into a `CancellablePromise`.  If a promise chain is initiazed with a `CancellablePromise`, then the entire chain is cancellable.  Calling `cancel()` on any promise in a promise chain cancels the entire chain.  For example:

```swift
let promise = firstly {
    /* The 'cancellable' function initiates a cancellable promise chain by
       returning a 'CancellablePromise'. */
    cancellable(login())
}.then { creds in
    cancellable(fetch(avatar: creds.user))
}.done { image in
    self.imageView = image
}.catch(policy: .allErrors) { error in
    if error.isCancelled {
        // the chain has been cancelled!
    }
}

// …

/* 'promise' here refers to the last promise in the chain.  Calling 'cancel' on
   any promise in the chain cancels the entire chain.  Therefore cancelling the
   last promise in the chain cancels everything.
   
   Note: It may be desirable to hold on to the 'CancelContext' directly rather than a
   promise so that the promise can be deallocated by ARC when it is resolved. */
promise.cancel()
```

### Creating a partially cancellable chain

A `CancellablePromise` cannot be used directly in the middle of a standard (non-cancellable) promise chain.  However, it <b>is</b> possible to create a partially cancellable promise chain.

`CancellablePromise` wraps a delegate `Promise`, which can be accessed with the `promise` property.  The above example can be modified as follows so that once `login()` completes, the chain can no longer be cancelled:

```swift
/// Convert a cancellable chain to a standard chain

/* Here, by calling 'promise.then' rather than 'then' the chain is converted from a cancellable
   promise chain to a standard promise chain. In this example, calling 'cancel()' during 'login'
   will cancel the chain but calling 'cancel()' during the 'fetch' operation will have no effect: */
let cancellablePromise = firstly {
    promise = cancellable(login())
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

A non-cancellable chain can be converted to a cancellable chain in the middle of the chain as follows:

```swift
/// Convert a standard chain to a cancellable chain

/* In this example, calling 'cancel()' during 'login' will not cancel the login.  However,
   the chain will be cancelled immediately, and the 'fetch' will not be executed.  If 'cancel()'
   is called during the 'fetch' then both the 'fetch' itself and the promise chain will be
   cancelled immediately. */
let promise = cancellable(firstly {
    login()
}).then {
    cancellable(fetch(avatar: creds.user))     
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

# Core API

The following classes, methods and functions have been added to PromiseKit to support cancellation. Existing functions or methods with underlying tasks that can be cancelled are indicated by being wrapped with 'cancellable()'.

<pre><code><b>Global functions</b>
    cancellable(_:)                 - Accepts a Promise or Guarantee and returns a CancellablePromise,
                                      which is a cancellable variant of the given Promise or Guarantee
    
    cancellable(after(seconds:))    - 'after' with seconds can be cancelled
    cancellable(after(_:))          - 'after' with interval can be cancelled

    firstly(execute:)               - Accepts body returning CancellablePromise
    hang(_:)                        - Accepts CancellablePromise
    race(_:)                        - Accepts [CancellablePromise]
    when(fulfilled:)                - Accepts [CancellablePromise]
    when(fulfilled:concurrently:)   - Accepts iterator of type CancellablePromise
    when(resolved:)                 - Accepts [CancellablePromise]

<b>CancellablePromise properties and methods</b>
    promise                         - Delegate Promise for this CancellablePromise
    result                          - The current Result
    
    init(_ bridge:<span style="color:gray;"><i>cancelContext</i>:</span>)   - Initialize a new cancellable promise bound to the provided Thenable
    init(<span style="color:gray;"><i>task</i>:</span>resolver body:).      - Initialize a new cancellable promise that can be resolved with
                                       the provided '(Resolver) throws -> Void' body
    init(<span style="color:gray;"><i>task</i>:</span>promise:resolver:)    - Initialize a new cancellable promise using the given Promise
                                       and its Resolver
    init(<span style="color:gray;"><i>task</i>:</span>error:)               - Initialize a new rejected cancellable promise
    init(<span style="color:gray;"><i>task</i>:</span>)                     - Initializes a new cancellable promise fulfilled with Void
 
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
    appendCancellableTask(_ task:<span style="color:gray;"><i>reject</i>:</span>)  - Append the CancellableTask to our cancel context
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
# <mark><b>cancellable</b></mark>(Alamofire.request("http://example.com", method: .get).responseDecodable(DecodableObject.self))
#     is equivalent to
# Alamofire.request("http://example.com", method: .get).<mark><b>cancellable</b></mark>ResponseDecodable(DecodableObject.self)

pod "PromiseKit/Bolts"
# CancellablePromise(…).then() { _ -> BFTask<NSString> in /*…*/ }  // Returns <mark><b>CancellablePromise</b></mark>

pod "PromiseKit/CoreLocation"
# <mark><b>cancellable</b></mark>(CLLocationManager.requestLocation()).then { /*…*/ }

pod "PromiseKit/Foundation"
# <mark><b>cancellable</b></mark>(URLSession.shared.dataTask())(.promise, with: request).then { /*…*/ }

pod "PromiseKit/MapKit"
# <mark><b>cancellable</b></mark>(MKDirections(…).calculate()).then { /*…*/ }

pod "PromiseKit/OMGHTTPURLRQ"
# <mark><b>cancellable</b></mark>(URLSession.shared.GET("http://example.com")).then { /*…*/ }

pod "PromiseKit/StoreKit"
# <mark><b>cancellable</b></mark>(SKProductsRequest(…).start(.promise)).then { /*…*/ }

pod "PromiseKit/SystemConfiguration"
# <mark><b>cancellable</b></mark>(SCNetworkReachability.promise()).then { /*…*/ }

pod "PromiseKit/UIKit"
# <mark><b>cancellable</b></mark>(UIViewPropertyAnimator(…).startAnimation(.promise)).then { /*…*/ }
</code></pre>

Here is a complete list of PromiseKit extension methods that support cancellation:

[Alamofire](http://github.com/PromiseKit/Alamofire-)

<pre><code>Alamofire.DataRequest
    <mark><b>cancellable</b></mark>(response(_:<span style="color:gray;"><i>queue</i>:</span>))
    <mark><b>cancellable</b></mark>(responseData(<span style="color:gray;"><i>queue</i>:</span>))
    <mark><b>cancellable</b></mark>(responseString(<span style="color:gray;"><i>queue</i>:</span>))
    <mark><b>cancellable</b></mark>(responseJSON(<span style="color:gray;"><i>queue</i>:</span><span style="color:gray;"><i>options</i>:</span>))
    <mark><b>cancellable</b></mark>(responsePropertyList(<span style="color:gray;"><i>queue</i>:</span><span style="color:gray;"><i>options</i>:</span>))
    <mark><b>cancellable</b></mark>(responseDecodable<T>(<span style="color:gray;"><i>queue</i>:</span>:<span style="color:gray;"><i>decoder</i>:</span>))
    <mark><b>cancellable</b></mark>(responseDecodable<T>(_ type:<span style="color:gray;"><i>queue</i>:</span><span style="color:gray;"><i>decoder</i>:</span>))
    cancellableResponse(_:<span style="color:gray;"><i>queue</i>:</span>)
    cancellableResponseData(<span style="color:gray;"><i>queue</i>:</span>)
    cancellableResponseString(<span style="color:gray;"><i>queue</i>:</span>)
    cancellableResponseJSON(<span style="color:gray;"><i>queue</i>:</span><span style="color:gray;"><i>options</i>:</span>)
    cancellableResponsePropertyList(<span style="color:gray;"><i>queue</i>:</span><span style="color:gray;"><i>options</i>:</span>)
    cancellableResponseDecodable<T>(<span style="color:gray;"><i>queue</i>:</span>:<span style="color:gray;"><i>decoder</i>:</span>)
    cancellableResponseDecodable<T>(_ type:<span style="color:gray;"><i>queue</i>:</span><span style="color:gray;"><i>decoder</i>:</span>)

Alamofire.DownloadRequest
    <mark><b>cancellable</b></mark>(response(_:<span style="color:gray;"><i>queue</i>:</span>))
    <mark><b>cancellable</b></mark>(responseData(<span style="color:gray;"><i>queue</i>:</span>))
    cancellableResponse(_:<span style="color:gray;"><i>queue</i>:</span>)
    cancellableResponseData(<span style="color:gray;"><i>queue</i>:</span>)
</code></pre>

[Bolts](http://github.com/PromiseKit/Bolts)

<pre><code>CancellablePromise&lt;T&gt;
    then&lt;U&gt;(<span style="color:gray;"><i>on: DispatchQueue?</i></span>, body: (T) -> BFTask&lt;U&gt;) -> CancellablePromise<U?> 
</code></pre>

[CoreLocation](http://github.com/PromiseKit/CoreLocation)

<pre><code>CLLocationManager
    <mark><b>cancellable</b></mark>(requestLocation(<span style="color:gray;"><i>authorizationType</i>:</span><span style="color:gray;"><i>satisfying</i>:</span>))
    <mark><b>cancellable</b></mark>(requestAuthorization(<span style="color:gray;"><i>type requestedAuthorizationType</i>:</span>))
    cancellableRequestLocation(<span style="color:gray;"><i>authorizationType</i>:</span><span style="color:gray;"><i>satisfying</i>:</span>)
    cancellableRequestAuthorization(<span style="color:gray;"><i>type requestedAuthorizationType</i>:</span>)
</code></pre>

[Foundation](http://github.com/PromiseKit/Foundation)

<pre><code>NotificationCenter:
    <mark><b>cancellable</b></mark>(observe(<span style="color:gray;"><i>once:object:</i></span>))
    cancellableObserve(<span style="color:gray;"><i>once:object:</i></span>)

NSObject
    <mark><b>cancellable</b></mark>(observe(_:keyPath:))
    cancellableObserve(_:keyPath:)

Process
    <mark><b>cancellable</b></mark>(launch(_:))
    cancellableLaunch(_:)

URLSession
    <mark><b>cancellable</b></mark>(dataTask(_:with:))
    <mark><b>cancellable</b></mark>(uploadTask(_:with:from:))
    <mark><b>cancellable</b></mark>(uploadTask(_:with:fromFile:))
    <mark><b>cancellable</b></mark>(downloadTask(_:with:to:))
    cancellableDataTask(_:with:)
    cancellableUploadTask(_:with:from:)
    cancellableUploadTask(_:with:fromFile:)
    cancellableDownloadTask(_:with:to:)

CancellablePromise
    validate()
</code></pre>

[HomeKit](http://github.com/PromiseKit/HomeKit)  

<pre><code>HMPromiseAccessoryBrowser
    <mark><b>cancellable</b></mark>(start(scanInterval:))
    cancellableStart(scanInterval:)

HMHomeManager
    <mark><b>cancellable</b></mark>(homes())
    cancellableHomes()
</code></pre>

[MapKit](http://github.com/PromiseKit/MapKit)  

<pre><code>MKDirections
    <mark><b>cancellable</b></mark>(calculate())
    <mark><b>cancellable</b></mark>(calculateETA())
    cancellableCalculate()
    cancellableCalculateETA()
    
MKMapSnapshotter
    <mark><b>cancellable</b></mark>(start())
    cancellableStart()
</code></pre>

[StoreKit](http://github.com/PromiseKit/StoreKit)  

<pre><code>SKProductsRequest
    <mark><b>cancellable</b></mark>(start(_:))
    cancellableStart(_:)
    
SKReceiptRefreshRequest
    <mark><b>cancellable</b></mark>(promise())
    cancellablePromise()
</code></pre>

[SystemConfiguration](http://github.com/PromiseKit/SystemConfiguration)

<pre><code>SCNetworkReachability
    <mark><b>cancellable</b></mark>(promise())
    cancellablePromise()
</code></pre>

[UIKit](http://github.com/PromiseKit/UIKit)  

<pre><code>UIViewPropertyAnimator
    <mark><b>cancellable</b></mark>(startAnimation(_:))
    cancellableStartAnimation(_:)
</code></pre>

## Choose Your Networking Library

All the networking library extensions supported by PromiseKit are now simple to cancel!

[Alamofire](http://github.com/PromiseKit/Alamofire-)

```swift
// pod 'PromiseKit/Alamofire'
// # https://github.com/PromiseKit/Alamofire

let context = firstly {
    cancellable(Alamofire
        .request("http://example.com", method: .post, parameters: params)
        .responseDecodable(Foo.self))
}.done { foo in
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
    cancellable(URLSession.shared.dataTask(.promise, with: try makeUrlRequest()))
}.map {
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
    cancellable(login()) // Use the 'cancellable' function to initiate a cancellable promise chain
}.then { creds in
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

* Fully support concurrecy, where all code is thead-safe

* Provide cancellable support for all PromiseKit extensions whose native tasks can be cancelled (e.g. Foundation, CoreLocation, Alamofire, etc.)

* Support cancellation for all PromiseKit primitives such as 'after', 'firstly', 'when', 'race'

* Provide a simple way to make new types of cancellable promises

* Ensure promise branches are properly cancelled.  For example:

```swift
import Alamofire
import PromiseKit

func updateWeather(forCity searchName: String) {
    refreshButton.startAnimating()
    let context = firstly {
        cancellable(getForecast(forCity: searchName))
    }.done { response in
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
       called in the middle of 'updateUI()', then the chain will immediately be rejected.
       However, the 'updateUI' call will complete normally because it is not cancellable.
       Its return value (if any) will be discarded. */
    context.cancel()
}

func getForecast(forCity name: String) -> CancellablePromise<WeatherInfo> {
    return firstly {
        cancellable(Alamofire.request("https://autocomplete.weather.com/\(name)")
            .responseDecodable(AutoCompleteCity.self))
    }.then { city in
        cancellable(Alamofire.request("https://forecast.weather.com/\(city.name)")
            .responseDecodable(WeatherResponse.self)) 
    }.map { response in
        format(response)
    }
}
```

