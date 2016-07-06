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
     to use instead: Promise.pending()

     - SeeAlso: http://promisekit.org/sealing-your-own-promises/
     - SeeAlso: http://promisekit.org/wrapping-delegation/
     - SeeAlso: pending()
    */
    public init(resolvers: @noescape (fulfill: (T) -> Void, reject: (ErrorProtocol) -> Void) throws -> Void) {
        var resolve: ((Resolution<T>) -> Void)!
        state = UnsealedState(resolver: &resolve)
        do {
            try resolvers(fulfill: { resolve(.fulfilled($0)) }, reject: { error in
                if self.isPending {
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
             return Promise.wrap { resolve in
                 KittenFetcher.fetchWithCompletionBlock(resolve)
             }
         }

     - SeeAlso: init(resolvers:)
    */
    public class func wrap(resolver: @noescape ((T?, NSError?) -> Void) throws -> Void) -> Promise {
        return Promise(sealant: { resolve in
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
             return Promise.wrap { resolve in
                 KittenFetcher.fetchWithCompletionBlock(resolve)
             }
         }

     - SeeAlso: init(resolvers:)
    */
    public class func wrap(resolver: @noescape ((T, NSError?) -> Void) throws -> Void) -> Promise  {
        return Promise(sealant: { resolve in
            try resolver { obj, err in
                if let err = err {
                    resolve(.rejected(err, ErrorConsumptionToken(err)))
                } else {
                    resolve(.fulfilled(obj))
                }
            }
        })
    }

    private init(state: SealedState<Resolution<T>>) {
        self.state = state
    }

    /**
     Create an already fulfilled promise.
    */
    public class func resolved(value: T) -> Promise {
        return Promise(state: SealedState(resolution: .fulfilled(value)))
    }

    /**
      Convenience function to create a resolved void promise.
      - Note: provided because we cannot specialize for Void promises in Swift 3, so `func resolved() -> Promise<Void>` would complain in usage that it couldn't determine T, this is a work-around since T is in the parameter list and thus Swift infers Void when called `()`.
    */
    public class func fulfilled(_ value: T) -> Promise {
        return Promise(state: SealedState(resolution: .fulfilled(value)))
    }

    /**
     Create an already rejected promise.
     */
    public class func resolved(error: ErrorProtocol) -> Promise {
        return Promise(state: SealedState(resolution: .rejected(error, ErrorConsumptionToken(error))))
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
     A `typealias` for the return values of `pending()`. Simplifies declaration of properties that reference the values' containing tuple when this is necessary. For example, when working with multiple `pendingPromise.fulfilled()`s within the same scope, or when the promise initialization must occur outside of the caller's initialization.

         class Foo: BarDelegate {
            var task: Promise<Int>.PendingTuple?
         }

     - SeeAlso: pending()
     */
    public typealias PendingTuple = (promise: Promise, fulfill: (T) -> Void, reject: (ErrorProtocol) -> Void)

    /**
     Making promises that wrap asynchronous delegation systems or other larger asynchronous systems without a simple completion handler is easier with pending.

         class Foo: BarDelegate {
             let (promise, fulfill, reject) = Promise<Int>.pending()
    
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
    public class func pending() -> PendingTuple {
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
    */
    public func then<U>(on q: DispatchQueue = PMKDefaultDispatchQueue(), execute body: (T) throws -> U) -> Promise<U> {
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

           URLSession.GET(url1).then { (data: NSData) -> Promise<Data> in
               //…
               return URLSession.GET(url2)
           }.then { data in
               //…
           }
    */
    public func then<U>(on q: DispatchQueue = PMKDefaultDispatchQueue(), execute body: (T) throws -> Promise<U>) -> Promise<U> {
        var rv: Promise<U>!
        rv = Promise<U>(when: self) { resolution, resolve in
            switch resolution {
            case .rejected(let error):
                resolve(.rejected((error.0, error.1)))
            case .fulfilled(let value):
                contain_zalgo(q, rejecter: resolve) {
                    let promise = try body(value)
                    guard promise !== rv else { throw Error.returnedSelf }
                    promise.pipe(resolve)
                }
            }
        }
        return rv
    }

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
    */
    public func then(on q: DispatchQueue = PMKDefaultDispatchQueue(), execute body: (T) throws -> AnyPromise) -> Promise<AnyObject?> {
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

    /**
     The provided closure is executed when this promise is rejected.

     Rejecting a promise cascades: rejecting all subsequent promises (unless
     recover is invoked) thus you will typically place your catch at the end
     of a chain. Often utility promises will not have a catch, instead
     delegating the error handling to the caller.

     The provided closure runs on PMKDefaultDispatchQueue by default.

     - Parameter policy: The default policy does not execute your handler for cancellation errors. See registerCancellationError for more documentation.
     - Parameter body: The handler to execute if this promise is rejected.
    */
    public func `catch`(on q: DispatchQueue = PMKDefaultDispatchQueue(), policy: CatchPolicy = .allErrorsExceptCancellation, execute body: (ErrorProtocol) -> Void) {
        func consume(_ error: ErrorProtocol, _ token: ErrorConsumptionToken) {
            token.consumed = true
            body(error)
        }

        pipe { resolution in
            switch (resolution, policy) {
            case (let .rejected(error, token), .allErrorsExceptCancellation):
                contain_zalgo(q) {
                    guard let cancellableError = error as? CancellableError where cancellableError.isCancelled else {
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
     The provided closure is executed when this promise is rejected giving you
     an opportunity to recover from the error and continue the promise chain.
    */
    public func recover(on q: DispatchQueue = PMKDefaultDispatchQueue(), execute body: (ErrorProtocol) throws -> Promise) -> Promise {
        var rv: Promise!
        rv = Promise(when: self) { resolution, resolve in
            switch resolution {
            case .rejected(let error, let token):
                contain_zalgo(q, rejecter: resolve) {
                    token.consumed = true
                    let promise = try body(error)
                    guard promise !== rv else { throw Error.returnedSelf }
                    promise.pipe(resolve)
                }
            case .fulfilled:
                resolve(resolution)
            }
        }
        return rv
    }

    public func recover(on q: DispatchQueue = PMKDefaultDispatchQueue(), execute body: (ErrorProtocol) throws -> T) -> Promise {
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
         somePromise.fulfilled().then {
             //…
         }.always {
             UIApplication.sharedApplication().networkActivityIndicatorVisible = false
         }

     - Parameter on: The queue on which body should be executed.
     - Parameter body: The closure that is executed when this Promise is resolved.
    */
    public func always(on q: DispatchQueue = PMKDefaultDispatchQueue(), execute body: () -> Void) -> Promise {
        return Promise(when: self) { resolution, resolve in
            contain_zalgo(q) {
                body()
                resolve(resolution)
            }
        }
    }

//MARK: deprecations

    @available(*, unavailable, renamed: "always()")
    public func finally(on: DispatchQueue = PMKDefaultDispatchQueue(), execute body: () -> Void) -> Promise { abort() }

    @available(*, unavailable, renamed: "pending()")
    public class func `defer`() -> PendingTuple { abort() }

    @available(*, unavailable, renamed: "pending()")
    public class func `pendingPromise`() -> PendingTuple { abort() }

    @available (*, unavailable, renamed: "resolved(value:)")
    public convenience init(_ value: T) { abort() }

    @available (*, unavailable, renamed: "fulfilled()")
    public convenience init() { abort() }

    @available (*, unavailable, renamed: "resolved(error:)")
    public convenience init(error: ErrorProtocol) { abort() }

    @available(*, unavailable, message: "deprecated: use then(on: DispatchQueue.global())")
    public func thenInBackground<U>(execute body: (T) throws -> U) -> Promise<U> { abort() }

//MARK: disallow `Promise<ErrorProtocol>`

    @available(*, unavailable, message: "cannot instantiate Promise<ErrorProtocol>")
    public init<T: ErrorProtocol>(_ value: T) { abort() }

    @available(*, unavailable, message: "cannot instantiate Promise<ErrorProtocol>")
    public convenience init<T: ErrorProtocol>(resolvers: @noescape(fulfill: (T) -> Void, reject: (ErrorProtocol) -> Void) throws -> Void) { abort() }

    @available(*, unavailable, message: "cannot instantiate Promise<ErrorProtocol>")
    public convenience init<T: ErrorProtocol>(resolver: @noescape ((T?, NSError?) -> Void) throws -> Void) { abort() }

    @available(*, unavailable, message: "cannot instantiate Promise<ErrorProtocol>")
    public convenience init<T: ErrorProtocol>(resolver: @noescape ((T, NSError?) -> Void) throws -> Void) { abort() }

    @available(*, unavailable, message: "cannot instantiate Promise<ErrorProtocol>")
    public class func pending<T: ErrorProtocol>() -> (promise: Promise, fulfill: (T) -> Void, reject: (ErrorProtocol) -> Void) { abort() }

//MARK: disallow returning `ErrorProtocol`

    @available (*, unavailable, message: "instead of returning the error; throw")
    public func then<U: ErrorProtocol>(on: DispatchQueue = PMKDefaultDispatchQueue(), execute body: (T) throws -> U) -> Promise<U> { abort() }

    @available (*, unavailable, message: "instead of returning the error; throw")
    public func recover<T: ErrorProtocol>(on: DispatchQueue = PMKDefaultDispatchQueue(), execute body: (ErrorProtocol) throws -> T) -> Promise { abort() }

//MARK: disallow returning `Promise?`

    @available(*, unavailable, message: "unwrap the promise")
    public func then<U>(on: DispatchQueue = PMKDefaultDispatchQueue(), execute body: (T) throws -> Promise<U>?) -> Promise<U> { abort() }

    @available(*, unavailable, message: "unwrap the promise")
    public func then(on: DispatchQueue = PMKDefaultDispatchQueue(), execute body: (T) throws -> AnyPromise?) -> Promise<AnyObject?> { abort() }

    @available(*, unavailable, message: "unwrap the promise")
    public func recover(on: DispatchQueue = PMKDefaultDispatchQueue(), execute body: (ErrorProtocol) throws -> Promise?) -> Promise { abort() }
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
        if Thread.isMainThread {
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
public func firstly<T>(execute body: @noescape () throws -> Promise<T>) -> Promise<T> {
    do {
        return try body()
    } catch {
        return Promise.resolved(error: error)
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
public func firstly(execute body: @noescape () throws -> AnyPromise) -> Promise<AnyObject?> {
    return Promise { resolve in
        try body().pipe(resolve)
    }
}

@available(*, unavailable, message: "instead of returning the error; throw")
public func firstly<T: ErrorProtocol>(execute body: @noescape () throws -> T) -> Promise<T> { abort() }


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
