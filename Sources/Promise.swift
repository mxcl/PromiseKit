import Dispatch
import Foundation.NSError

/**
 A *promise* represents the future value of a task.

 To obtain the value of a promise we call `then`.

 Promises are chainable: `then` returns a promise, you can call `then` on
 that promise, which returns a promise, you can call `then` on that
 promise, et cetera.

 Promises start in a pending state and *resolve* with a value to become
 *fulfilled* or with an `ErrorType` to become rejected.

 - SeeAlso: [PromiseKit `then` Guide](http://promisekit.org/then/)
 - SeeAlso: [PromiseKit Chaining Guide](http://promisekit.org/chaining/)
*/
public class Promise<T> {
    let state: State<Resolution<T>>

    /**
     Create a new pending promise.

     Use this method when wrapping asynchronous systems that do *not* use
     promises so that they can be involved in promise chains.

     Don’t use this method if you already have promises! Instead, just return
     your promise!

     The closure you pass is executed immediately on the calling thread.

         func fetchKitten() -> Promise<UIImage> {
             return Promise { fulfill, reject in
                 KittenFetcher.fetchWithCompletionBlock({ img, err in
                     if err == nil {
                         if img.size.width > 0 {
                             fulfill(img)
                         } else {
                             reject(Error.ImageTooSmall)
                         }
                     } else {
                         reject(err)
                     }
                 })
             }
         }

     - Parameter resolvers: The provided closure is called immediately.
     Inside, execute your asynchronous system, calling fulfill if it suceeds
     and reject for any errors.

     - Returns: return A new promise.

     - Note: If you are wrapping a delegate-based system, we recommend
     to use instead: Promise.pendingPromise()

     - SeeAlso: http://promisekit.org/sealing-your-own-promises/
     - SeeAlso: http://promisekit.org/wrapping-delegation/
     - SeeAlso: init(resolver:)
    */
    public init(resolvers: @noescape (fulfill: (T) -> Void, reject: (ErrorProtocol) -> Void) throws -> Void) {
        var resolve: ((Resolution<T>) -> Void)!
        state = UnsealedState(resolver: &resolve)
        do {
            try resolvers(fulfill: { resolve(.fulfilled($0)) }, reject: { error in
                if self.pending {
                    resolve(.rejected(error, ErrorConsumptionToken(error)))
                } else {
                    NSLog("PromiseKit: Warning: reject called on already rejected Promise: %@", "\(error)")
                }
            })
        } catch {
            resolve(.rejected(error, ErrorConsumptionToken(error)))
        }
    }

    /**
     Create a new pending promise.

     This initializer is convenient when wrapping asynchronous systems that
     use common patterns. For example:

         func fetchKitten() -> Promise<UIImage> {
             return Promise { resolve in
                 KittenFetcher.fetchWithCompletionBlock(resolve)
             }
         }

     - SeeAlso: init(resolvers:)
    */
    public convenience init(resolver: @noescape ((T?, NSError?) -> Void) throws -> Void) {
        self.init(sealant: { resolve in
            try resolver { obj, err in
                if let obj = obj {
                    resolve(.fulfilled(obj))
                } else if let err = err {
                    resolve(.rejected(err, ErrorConsumptionToken(err as ErrorProtocol)))
                } else {
                    resolve(.rejected(Error.doubleOhSux0r, ErrorConsumptionToken(Error.doubleOhSux0r)))
                }
            }
        })
    }

    /**
     Create a new pending promise.

     This initializer is convenient when wrapping asynchronous systems that
     use common patterns. For example:

         func fetchKitten() -> Promise<UIImage> {
             return Promise { resolve in
                 KittenFetcher.fetchWithCompletionBlock(resolve)
             }
         }

     - SeeAlso: init(resolvers:)
    */
    public convenience init(resolver: @noescape ((T, NSError?) -> Void) throws -> Void) {
        self.init(sealant: { resolve in
            try resolver { obj, err in
                if let err = err {
                    resolve(.rejected(err, ErrorConsumptionToken(err)))
                } else {
                    resolve(.fulfilled(obj))
                }
            }
        })
    }

    /**
     Create a new fulfilled promise.
    */
    public init(_ value: T) {
        state = SealedState(resolution: .fulfilled(value))
    }

    @available(*, unavailable, message:"T cannot conform to ErrorType")
    public init<T: ErrorProtocol>(_ value: T) { abort() }

    /**
     Create a new rejected promise.
    */
    public init(error: ErrorProtocol) {
        /**
          Implementation note, the error label is necessary to prevent:

             let p = Promise(ErrorType())

          Resulting in Promise<ErrorType>. The above @available annotation
          does not help for some reason. A work-around is:

             let p: Promise<Void> = Promise(ErrorType())
        
          But I can’t expect users to do this.
        */
        state = SealedState(resolution: .rejected(error, ErrorConsumptionToken(error)))
    }

    /**
     Careful with this, it is imperative that sealant can only be called once
     or you will end up with spurious unhandled-errors due to possible double
     rejections and thus immediately deallocated ErrorConsumptionTokens.
    */
    init(sealant: @noescape ((Resolution<T>) -> Void) throws -> Void) {
        var resolve: ((Resolution<T>) -> Void)!
        state = UnsealedState(resolver: &resolve)
        do {
            try sealant(resolve)
        } catch {
            resolve(.rejected(error, ErrorConsumptionToken(error)))
        }
    }

    /**
     A `typealias` for the return values of `pendingPromise()`. Simplifies declaration of properties that reference the values' containing tuple when this is necessary. For example, when working with multiple `pendingPromise()`s within the same scope, or when the promise initialization must occur outside of the caller's initialization.

         class Foo: BarDelegate {
            var pendingPromise: Promise<Int>.PendingPromise?
         }

     - SeeAlso: pendingPromise()
     */
    public typealias PendingPromise = (promise: Promise, fulfill: (T) -> Void, reject: (ErrorProtocol) -> Void)

    /**
     Making promises that wrap asynchronous delegation systems or other larger asynchronous systems without a simple completion handler is easier with pendingPromise.

         class Foo: BarDelegate {
             let (promise, fulfill, reject) = Promise<Int>.pendingPromise()
    
             func barDidFinishWithResult(result: Int) {
                 fulfill(result)
             }
    
             func barDidError(error: NSError) {
                 reject(error)
             }
         }

     - Returns: A tuple consisting of: 
       1) A promise
       2) A function that fulfills that promise
       3) A function that rejects that promise
    */
    public class func pendingPromise() -> PendingPromise {
        var fulfill: ((T) -> Void)!
        var reject: ((ErrorProtocol) -> Void)!
        let promise = Promise { fulfill = $0; reject = $1 }
        return (promise, fulfill, reject)
    }

    func pipe(_ body: (Resolution<T>) -> Void) {
        state.get { seal in
            switch seal {
            case .pending(let handlers):
                handlers.append(body)
            case .resolved(let resolution):
                body(resolution)
            }
        }
    }

    private convenience init<U>(when: Promise<U>, body: (Resolution<U>, (Resolution<T>) -> Void) -> Void) {
        self.init { resolve in
            when.pipe { resolution in
                body(resolution, resolve)
            }
        }
    }

    /**
     The provided closure is executed when this Promise is resolved.

     - Parameter on: The queue on which body should be executed.
     - Parameter body: The closure that is executed when this Promise is fulfilled.
     - Returns: A new promise that is resolved with the value returned from the provided closure. For example:

           NSURLConnection.GET(url).then { (data: NSData) -> Int in
               //…
               return data.length
           }.then { length in
               //…
           }

     - SeeAlso: `thenInBackground`
    */
    public func then<U>(on q: DispatchQueue = PMKDefaultDispatchQueue(), _ body: (T) throws -> U) -> Promise<U> {
        return Promise<U>(when: self) { resolution, resolve in
            switch resolution {
            case .rejected(let error):
                resolve(.rejected((error.0, error.1)))
            case .fulfilled(let value):
                contain_zalgo(q, rejecter: resolve) {
                    resolve(.fulfilled(try body(value)))
                }
            }
        }
    }

    /**
     The provided closure is executed when this Promise is resolved.

     - Parameter on: The queue on which body should be executed.
     - Parameter body: The closure that is executed when this Promise is fulfilled.
     - Returns: A new promise that is resolved when the Promise returned from the provided closure resolves. For example:

           NSURLSession.GET(url1).then { (data: NSData) -> Promise<NSData> in
               //…
               return NSURLSession.GET(url2)
           }.then { data in
               //…
           }

     - SeeAlso: `thenInBackground`
    */
    public func then<U>(on q: DispatchQueue = PMKDefaultDispatchQueue(), _ body: (T) throws -> Promise<U>) -> Promise<U> {
        return Promise<U>(when: self) { resolution, resolve in
            switch resolution {
            case .rejected(let error):
                resolve(.rejected((error.0, error.1)))
            case .fulfilled(let value):
                contain_zalgo(q, rejecter: resolve) {
                    let promise = try body(value)
                    guard promise !== self else { throw Error.returnedSelf }
                    promise.pipe(resolve)
                }
            }
        }
    }

    @available(*, unavailable)
    public func then<U>(_ on: DispatchQueue = PMKDefaultDispatchQueue(), _ body: (T) throws -> Promise<U>?) -> Promise<U> { abort() }

    /**
     The provided closure is executed when this Promise is resolved.

     - Parameter on: The queue on which body should be executed.
     - Parameter body: The closure that is executed when this Promise is fulfilled.
     - Returns: A new promise that is resolved when the AnyPromise returned from the provided closure resolves. For example:

           NSURLSession.GET(url).then { (data: NSData) -> AnyPromise in
               //…
               return SCNetworkReachability()
           }.then { _ in
               //…
           }

     - SeeAlso: `thenInBackground`
    */
    public func then(on q: DispatchQueue = PMKDefaultDispatchQueue(), _ body: (T) throws -> AnyPromise) -> Promise<AnyObject?> {
        return Promise<AnyObject?>(when: self) { resolution, resolve in
            switch resolution {
            case .rejected(let error):
                resolve(.rejected((error.0, error.1)))
            case .fulfilled(let value):
                contain_zalgo(q, rejecter: resolve) {
                    try body(value).pipe(resolve)
                }
            }
        }
    }

    @available(*, unavailable)
    public func then(_ on: DispatchQueue = PMKDefaultDispatchQueue(), body: (T) throws -> AnyPromise?) -> Promise<AnyObject?> { abort() }

    /**
     The provided closure is executed on the default background queue when this Promise is fulfilled.

     This method is provided as a convenience for `then`.

     - SeeAlso: `then`
    */
    public func thenInBackground<U>(_ body: (T) throws -> U) -> Promise<U> {
        return then(on: DispatchQueue.global(), body)
    }

    /**
     The provided closure is executed on the default background queue when this Promise is fulfilled.

     This method is provided as a convenience for `then`.

     - SeeAlso: `then`
    */
    public func thenInBackground<U>(_ body: (T) throws -> Promise<U>) -> Promise<U> {
        return then(on: DispatchQueue.global(), body)
    }

    @available(*, unavailable)
    public func thenInBackground<U>(_ body: (T) throws -> Promise<U>?) -> Promise<U> { abort() }

    /**
     The provided closure is executed when this promise is rejected.

     Rejecting a promise cascades: rejecting all subsequent promises (unless
     recover is invoked) thus you will typically place your catch at the end
     of a chain. Often utility promises will not have a catch, instead
     delegating the error handling to the caller.

     The provided closure runs on PMKDefaultDispatchQueue by default.

     - Parameter policy: The default policy does not execute your handler for cancellation errors. See registerCancellationError for more documentation.
     - Parameter body: The handler to execute if this promise is rejected.
     - SeeAlso: `errorOnQueue`
    */
    public func error(policy: ErrorPolicy = .allErrorsExceptCancellation, _ body: (ErrorProtocol) -> Void) {
        errorOnQueue(policy: policy, body)
    }

    /**
     The provided closure is executed when this promise is rejected.

     Rejecting a promise cascades: rejecting all subsequent promises (unless
     recover is invoked) thus you will typically place your catch at the end
     of a chain. Often utility promises will not have a catch, instead
     delegating the error handling to the caller.

     The provided closure runs on PMKDefaultDispatchQueue by default.

     - Parameter on: The queue on which body should be executed.
     - Parameter policy: The default policy does not execute your handler for cancellation errors. See registerCancellationError for more documentation.
     - Parameter body: The handler to execute if this promise is rejected.
     - SeeAlso: `registerCancellationError`
     */
    public func errorOnQueue(on q: DispatchQueue = PMKDefaultDispatchQueue(), policy: ErrorPolicy = .allErrorsExceptCancellation, _ body: (ErrorProtocol) -> Void) {

        func consume(_ error: ErrorProtocol, _ token: ErrorConsumptionToken) {
            token.consumed = true
            body(error)
        }

        pipe { resolution in
            switch (resolution, policy) {
            case (let .rejected(error, token), .allErrorsExceptCancellation):
                contain_zalgo(q) {
                    guard let cancellableError = error as? CancellableErrorType where cancellableError.cancelled else {
                        consume(error, token)
                        return
                    }
                }
            case (let .rejected(error, token), _):
                contain_zalgo(q) {
                    consume(error, token)
                }
            case (.fulfilled, _):
                break
            }
        }
    }

    /**
     Provides an alias for the `error` function for cases where the Swift
     compiler cannot disambiguate from our `error` property. If you're
     having trouble with `error`, before using this alias, first try 
     being as explicit as possible with the types e.g.:

         }.error { (error:ErrorType) -> Void in
             //...
         }

     Or even using verbose function syntax:

         }.error({ (error:ErrorType) -> Void in
             //...
         })
     
     If you absolutely cannot get Swift to accept `error` then `onError`
     may be used instead as it does the same thing.
     
     - Warning: This alias will be unavailable in PromiseKit 4.0.0
     - SeeAlso: [https://github.com/mxcl/PromiseKit/issues/347](https://github.com/mxcl/PromiseKit/issues/347)
    */
    @available(*, deprecated, renamed:"error", message:"Temporary alias `onError` will eventually be removed and should only be used when the Swift compiler cannot be satisfied with `error`")
    public func onError(policy: ErrorPolicy = .allErrorsExceptCancellation, _ body: (ErrorProtocol) -> Void) {
        error(policy: policy, body)
    }

    /**
     The provided closure is executed when this promise is rejected giving you
     an opportunity to recover from the error and continue the promise chain.
    */
    public func recover(on q: DispatchQueue = PMKDefaultDispatchQueue(), _ body: (ErrorProtocol) throws -> Promise) -> Promise {
        return Promise(when: self) { resolution, resolve in
            switch resolution {
            case .rejected(let error, let token):
                contain_zalgo(q, rejecter: resolve) {
                    token.consumed = true
                    let promise = try body(error)
                    guard promise !== self else { throw Error.returnedSelf }
                    promise.pipe(resolve)
                }
            case .fulfilled:
                resolve(resolution)
            }
        }
    }

    @available(*, unavailable)
    public func recover(_ on: DispatchQueue = PMKDefaultDispatchQueue(), _ body: (ErrorProtocol) throws -> Promise?) -> Promise { abort() }

    public func recover(on q: DispatchQueue = PMKDefaultDispatchQueue(), _ body: (ErrorProtocol) throws -> T) -> Promise {
        return Promise(when: self) { resolution, resolve in
            switch resolution {
            case .rejected(let error, let token):
                contain_zalgo(q, rejecter: resolve) {
                    token.consumed = true
                    resolve(.fulfilled(try body(error)))
                }
            case .fulfilled:
                resolve(resolution)
            }
        }
    }

    /**
     The provided closure is executed when this Promise is resolved.

         UIApplication.sharedApplication().networkActivityIndicatorVisible = true
         somePromise().then {
             //…
         }.always {
             UIApplication.sharedApplication().networkActivityIndicatorVisible = false
         }

     - Parameter on: The queue on which body should be executed.
     - Parameter body: The closure that is executed when this Promise is resolved.
    */
    public func always(on q: DispatchQueue = PMKDefaultDispatchQueue(), _ body: () -> Void) -> Promise {
        return Promise(when: self) { resolution, resolve in
            contain_zalgo(q) {
                body()
                resolve(resolution)
            }
        }
    }

    @available(*, unavailable, renamed:"ensure")
    public func finally(_ on: DispatchQueue = PMKDefaultDispatchQueue(), body: () -> Void) -> Promise { abort() }

    @available(*, unavailable, renamed:"report")
    public func catch_(policy: ErrorPolicy = .allErrorsExceptCancellation, body: () -> Void) -> Promise { abort() }

    @available(*, unavailable, renamed:"pendingPromise")
    public class func defer_() -> (promise: Promise, fulfill: (T) -> Void, reject: (ErrorProtocol) -> Void) { abort() }

    @available(*, deprecated, renamed:"error")
    public func report(policy: ErrorPolicy = .allErrorsExceptCancellation, _ body: (ErrorProtocol) -> Void) { error(policy: policy, body) }

    @available(*, deprecated, renamed:"always")
    public func ensure(on q: DispatchQueue = PMKDefaultDispatchQueue(), _ body: () -> Void) -> Promise { return always(on: q, body) }
}

/**
 Zalgo is dangerous.

 Pass as the `on` parameter for a `then`. Causes the handler to be executed
 as soon as it is resolved. That means it will be executed on the queue it
 is resolved. This means you cannot predict the queue.

 In the case that the promise is already resolved the handler will be
 executed immediately.

 zalgo is provided for libraries providing promises that have good tests
 that prove unleashing zalgo is safe. You can also use it in your
 application code in situations where performance is critical, but be
 careful: read the essay at the provided link to understand the risks.

 - SeeAlso: http://blog.izs.me/post/59142742143/designing-apis-for-asynchrony
*/
public let zalgo: DispatchQueue = DispatchQueue(label: "Zalgo", attributes: [])

/**
 Waldo is dangerous.

 Waldo is zalgo, unless the current queue is the main thread, in which case
 we dispatch to the default background queue.

 If your block is likely to take more than a few milliseconds to execute,
 then you should use waldo: 60fps means the main thread cannot hang longer
 than 17 milliseconds. Don’t contribute to UI lag.

 Conversely if your then block is trivial, use zalgo: GCD is not free and
 for whatever reason you may already be on the main thread so just do what
 you are doing quickly and pass on execution.

 It is considered good practice for asynchronous APIs to complete onto the
 main thread. Apple do not always honor this, nor do other developers.
 However, they *should*. In that respect waldo is a good choice if your
 then is going to take a while and doesn’t interact with the UI.

 Please note (again) that generally you should not use zalgo or waldo. The
 performance gains are neglible and we provide these functions only out of
 a misguided sense that library code should be as optimized as possible.
 If you use zalgo or waldo without tests proving their correctness you may
 unwillingly introduce horrendous, near-impossible-to-trace bugs.

 - SeeAlso: zalgo
*/
public let waldo: DispatchQueue = DispatchQueue(label: "Waldo", attributes: [])

func contain_zalgo(_ q: DispatchQueue, block: () -> Void) {
    if q === zalgo {
        block()
    } else if q === waldo {
        if Thread.isMainThread() {
            DispatchQueue.global(attributes: DispatchQueue.GlobalAttributes(rawValue: UInt64(0))).async(execute: block)
        } else {
            block()
        }
    } else {
        q.async(execute: block)
    }
}

func contain_zalgo<T>(_ q: DispatchQueue, rejecter resolve: (Resolution<T>) -> Void, block: () throws -> Void) {
    contain_zalgo(q) {
        do {
            try block()
        } catch {
            resolve(.rejected(error, ErrorConsumptionToken(error)))
        }
    }
}


extension Promise {
    /**
     Void promises are less prone to generics-of-doom scenarios.
     - SeeAlso: when.swift contains enlightening examples of using `Promise<Void>` to simplify your code.
    */
    public func asVoid() -> Promise<Void> {
        return then(on: zalgo) { _ in return }
    }
}


extension Promise: CustomStringConvertible {
    public var description: String {
        return "Promise: \(state)"
    }
}

/**
 `firstly` can make chains more readable.

 Compare:

     NSURLConnection.GET(url1).then {
         NSURLConnection.GET(url2)
     }.then {
         NSURLConnection.GET(url3)
     }

 With:

     firstly {
         NSURLConnection.GET(url1)
     }.then {
         NSURLConnection.GET(url2)
     }.then {
         NSURLConnection.GET(url3)
     }
*/
public func firstly<T>(_ promise: @noescape () throws -> Promise<T>) -> Promise<T> {
    do {
        return try promise()
    } catch {
        return Promise(error: error)
    }
}

/**
 `firstly` can make chains more readable.

 Compare:

     SCNetworkReachability().then {
         NSURLSession.GET(url2)
     }.then {
         NSURLSession.GET(url3)
     }

 With:

     firstly {
         SCNetworkReachability()
     }.then {
         NSURLSession.GET(url2)
     }.then {
         NSURLSession.GET(url3)
     }
*/
public func firstly(_ promise: @noescape () throws -> AnyPromise) -> Promise<AnyObject?> {
    return Promise { resolve in
        try promise().pipe(resolve)
    }
}

@available(*, unavailable, message:"Instead, throw")
public func firstly<T: ErrorProtocol>(_ promise: @noescape () throws -> Promise<T>) -> Promise<T> {
    fatalError("Unavailable function")
}


public enum ErrorPolicy {
    case allErrors
    case allErrorsExceptCancellation
}


extension AnyPromise {
    private func pipe(_ resolve: (Resolution<AnyObject?>) -> Void) -> Void {
        pipe { (obj: AnyObject?) in
            if let error = obj as? NSError {
                resolve(.rejected(error, ErrorConsumptionToken(error)))
            } else {
                // possibly the value of this promise is a PMKManifold, if so
                // calling the objc `value` method will return the first item.
                resolve(.fulfilled(self.value(forKey: "value")))
            }
        }
    }
}


extension Promise {
    @available(*, unavailable, message:"T cannot conform to ErrorType")
    public convenience init<T: ErrorProtocol>(resolvers: @noescape(fulfill: (T) -> Void, reject: (ErrorProtocol) -> Void) throws -> Void) { abort() }

    @available(*, unavailable, message:"T cannot conform to ErrorType")
    public convenience init<T: ErrorProtocol>(resolver: @noescape ((T?, NSError?) -> Void) throws -> Void) { abort() }

    @available(*, unavailable, message:"T cannot conform to ErrorType")
    public convenience init<T: ErrorProtocol>(resolver: @noescape ((T, NSError?) -> Void) throws -> Void) { abort() }

    @available(*, unavailable, message:"T cannot conform to ErrorType")
    public class func pendingPromise<T: ErrorProtocol>() -> (promise: Promise, fulfill: (T) -> Void, reject: (ErrorProtocol) -> Void) { abort() }

    @available (*, unavailable, message:"U cannot conform to ErrorType")
    public func then<U: ErrorProtocol>(_ on: DispatchQueue = PMKDefaultDispatchQueue(), _ body: (T) throws -> U) -> Promise<U> { abort() }

    @available (*, unavailable, message:"U cannot conform to ErrorType")
    public func then<U: ErrorProtocol>(_ on: DispatchQueue = PMKDefaultDispatchQueue(), _ body: (T) throws -> Promise<U>) -> Promise<U> { abort() }

    @available(*, unavailable, message:"U cannot conform to ErrorType")
    public func thenInBackground<U: ErrorProtocol>(_ body: (T) throws -> U) -> Promise<U> { abort() }

    @available(*, unavailable, message:"U cannot conform to ErrorType")
    public func thenInBackground<U: ErrorProtocol>(_ body: (T) throws -> Promise<U>) -> Promise<U> { abort() }
}
