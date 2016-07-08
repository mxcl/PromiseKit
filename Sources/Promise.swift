import class Dispatch.DispatchQueue
import class Foundation.NSError
import func Foundation.NSLog


/**
 A *promise* represents the future value of a (usually) asynchronous task.

 To obtain the value of a promise we call `then`.

 Promises are chainable: `then` returns a promise, you can call `then` on
 that promise, which returns a promise, you can call `then` on that
 promise, et cetera.

 Promises start in a pending state and *resolve* with a value to become
 *fulfilled* or an `ErrorProtocol` to become rejected.

 - SeeAlso: [PromiseKit `then` Guide](http://promisekit.org/then/)
 - SeeAlso: [PromiseKit Chaining Guide](http://promisekit.org/chaining/)
*/
public class Promise<T> {
    let state: State<T>

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
     to use instead: `Promise.pending()`

     - SeeAlso: http://promisekit.org/sealing-your-own-promises/
     - SeeAlso: http://promisekit.org/wrapping-delegation/
     - SeeAlso: pending()
    */
    public init(resolvers: @noescape (fulfill: (T) -> Void, reject: (ErrorProtocol) -> Void) throws -> Void) {
        var resolve: ((Resolution<T>) -> Void)!
        do {
            state = UnsealedState(resolver: &resolve)
            try resolvers(fulfill: { resolve(.fulfilled($0)) }, reject: { error in
                if self.isPending {
                    resolve(Resolution(error))
                } else {
                    NSLog("PromiseKit: warning: reject called on already rejected Promise: \(error)")
                }
            })
        } catch {
            resolve(Resolution(error))
        }
    }

    private init(seal resolution: Resolution<T>) {
        self.state = SealedState(resolution: resolution)
    }

    /**
     Create an already fulfilled promise.
    */
    public class func resolved(value: T) -> Promise {
        return Promise(seal: .fulfilled(value))
    }

    /**
      Convenience function to create a resolved void promise.
      - Note: provided because we cannot specialize for Void promises in Swift 3, so `func resolved() -> Promise<Void>` would complain in usage that it couldn't determine T, this is a work-around since T is in the parameter list and thus Swift infers Void when called `()`.
    */
    public class func fulfilled(_ value: T) -> Promise {
        return Promise(seal: .fulfilled(value))
    }

    /**
     Create an already rejected promise.
     */
    public class func resolved(error: ErrorProtocol) -> Promise {
        return Promise(seal: Resolution(error))
    }

    /**
     Careful with this, it is imperative that sealant can only be called once
     or you will end up with spurious unhandled-errors due to possible double
     rejections and thus immediately deallocated ErrorConsumptionTokens.
    */
    init(sealant: @noescape ((Resolution<T>) -> Void) -> Void) {
        var resolve: ((Resolution<T>) -> Void)!
        state = UnsealedState(resolver: &resolve)
        sealant(resolve)
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

    /**
     The provided closure is executed when this Promise is resolved.

     - Parameter on: The queue to which your handler is dispatched.
     - Parameter body: The closure that is executed when this Promise is fulfilled.
     - Returns: A new promise that is resolved with the value returned from the provided closure. For example:

           NSURLConnection.GET(url).then { data -> Int in
               //…
               return data.length
           }.then { length in
               //…
           }
    */
    public func then<U>(on q: DispatchQueue = PMKDefaultDispatchQueue(), execute body: (T) throws -> U) -> Promise<U> {
        return Promise<U> { resolve in
            state.then(on: q, else: resolve) { value in
                resolve(.fulfilled(try body(value)))
            }
        }
    }

    /**
     The provided closure is executed when this `Promise` is resolved.

     - Parameter on: The queue to which your handler is dispatched.
     - Parameter body: The closure that is executed when this Promise is fulfilled.
     - Returns: A new promise that is resolved when the Promise returned from the provided closure resolves. For example:

           URLSession.GET(url1).then { data -> Promise<Data> in
               //…
               return URLSession.GET(url2)
           }.then { data in
               //…
           }
    */
    public func then<U>(on q: DispatchQueue = PMKDefaultDispatchQueue(), execute body: (T) throws -> Promise<U>) -> Promise<U> {
        var rv: Promise<U>!
        rv = Promise<U> { resolve in
            state.then(on: q, else: resolve) { value in
                let promise = try body(value)
                guard promise !== rv else { throw Error.returnedSelf }
                promise.state.pipe(resolve)
            }
        }
        return rv
    }

    /**
     The provided closure is executed when this promise is rejected.

     Rejecting a promise cascades: rejecting all subsequent promises (unless
     recover is invoked) thus you will typically place your catch at the end
     of a chain. Often utility promises will not have a catch, instead
     delegating the error handling to the caller.

     The provided closure runs on PMKDefaultDispatchQueue by default.

     - Parameter on: The queue to which your handler is dispatched.
     - Parameter policy: The default policy does not execute your handler for cancellation errors. See `registerCancellationError` for more documentation.
     - Parameter body: The handler to execute if this promise is rejected.
    */
    public func `catch`(on q: DispatchQueue = PMKDefaultDispatchQueue(), policy: CatchPolicy = .allErrorsExceptCancellation, execute body: (ErrorProtocol) -> Void) {
        state.catch(on: q, policy: policy, else: { _ in }, execute: body)
    }

    /**
     The provided closure is executed when this promise is rejected giving you
     an opportunity to recover from the error and continue the promise chain.
    */
    public func recover(on q: DispatchQueue = PMKDefaultDispatchQueue(), policy: CatchPolicy = .allErrorsExceptCancellation, execute body: (ErrorProtocol) throws -> Promise) -> Promise {
        var rv: Promise!
        rv = Promise { resolve in
            state.catch(on: q, policy: policy, else: resolve) { error in
                let promise = try body(error)
                guard promise !== rv else { throw Error.returnedSelf }
                promise.state.pipe(resolve)
            }
        }
        return rv
    }

    public func recover(on q: DispatchQueue = PMKDefaultDispatchQueue(), policy: CatchPolicy = .allErrorsExceptCancellation, execute body: (ErrorProtocol) throws -> T) -> Promise {
        return Promise { resolve in
            state.catch(on: q, policy: policy, else: resolve) { error in
                resolve(.fulfilled(try body(error)))
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
        state.always(on: q) { resolution in
            body()
        }
        return self
    }

    /**
      `tap` allows you to “tap” into a promise chain and inspect its result. The function you provide cannot mutate the chain.
 
          NSURLSession.GET(…).tap { result in
              print(result)
          }
     */
    public func tap(on q: DispatchQueue = PMKDefaultDispatchQueue(), execute body: (Result<T>) -> Void) -> Promise {
        state.always(on: q) { resolution in
            body(Result(resolution))
        }
        return self
    }

    /**
     Void promises are less prone to generics-of-doom scenarios.
     - SeeAlso: when.swift contains enlightening examples of using `Promise<Void>` to simplify your code.
     */
    public func asVoid() -> Promise<Void> {
        return then(on: zalgo) { _ in return }
    }

//MARK: deprecations

    @available(*, unavailable, renamed: "always()")
    public func finally(on: DispatchQueue = DispatchQueue.main, execute body: () -> Void) -> Promise { fatalError() }

    @available(*, unavailable, renamed: "always()")
    public func ensure(on: DispatchQueue = DispatchQueue.main, execute body: () -> Void) -> Promise { fatalError() }

    @available(*, unavailable, renamed: "pending()")
    public class func `defer`() -> PendingTuple { fatalError() }

    @available(*, unavailable, renamed: "pending()")
    public class func `pendingPromise`() -> PendingTuple { fatalError() }

    @available (*, unavailable, renamed: "resolved(value:)")
    public convenience init(_ value: T) { fatalError() }

    @available (*, unavailable, renamed: "fulfilled()")
    public convenience init() { fatalError() }

    @available (*, unavailable, renamed: "resolved(error:)")
    public convenience init(error: ErrorProtocol) { fatalError() }

    @available(*, unavailable, message: "deprecated: use then(on: DispatchQueue.global())")
    public func thenInBackground<U>(execute body: (T) throws -> U) -> Promise<U> { fatalError() }

    @available(*, unavailable, renamed: "catch")
    public func onError(policy: CatchPolicy = .allErrors, execute body: (ErrorProtocol) -> Void) { fatalError() }

    @available(*, unavailable, renamed: "catch")
    public func errorOnQueue(_ on: DispatchQueue, policy: CatchPolicy = .allErrors, execute body: (ErrorProtocol) -> Void) { fatalError() }

    @available(*, unavailable, renamed: "catch")
    public func error(policy: CatchPolicy, execute body: (ErrorProtocol) -> Void) { fatalError() }

    @available(*, unavailable, renamed: "catch")
    public func report(policy: CatchPolicy = .allErrors, execute body: (ErrorProtocol) -> Void) { fatalError() }

//MARK: disallow `Promise<ErrorProtocol>`

    @available(*, unavailable, message: "cannot instantiate Promise<ErrorProtocol>")
    public init<T: ErrorProtocol>(value: T) { fatalError() }

    @available(*, unavailable, message: "cannot instantiate Promise<ErrorProtocol>")
    public convenience init<T: ErrorProtocol>(resolvers: @noescape(fulfill: (T) -> Void, reject: (ErrorProtocol) -> Void) throws -> Void) { fatalError() }

    @available(*, unavailable, message: "cannot instantiate Promise<ErrorProtocol>")
    public class func wrap(resolver: @noescape ((T?, NSError?) -> Void) throws -> Void) -> Promise<ErrorProtocol> { fatalError() }

    @available(*, unavailable, message: "cannot instantiate Promise<ErrorProtocol>")
    public class func wrap(resolver: @noescape ((T, NSError?) -> Void) throws -> Void) -> Promise<ErrorProtocol> { fatalError() }

    @available(*, unavailable, message: "cannot instantiate Promise<ErrorProtocol>")
    public class func pending<T: ErrorProtocol>() -> (promise: Promise, fulfill: (T) -> Void, reject: (ErrorProtocol) -> Void) { fatalError() }

//MARK: disallow returning `ErrorProtocol`

    @available (*, unavailable, message: "instead of returning the error; throw")
    public func then<U: ErrorProtocol>(on: DispatchQueue = PMKDefaultDispatchQueue(), execute body: (T) throws -> U) -> Promise<U> { fatalError() }

    @available (*, unavailable, message: "instead of returning the error; throw")
    public func recover<T: ErrorProtocol>(on: DispatchQueue = PMKDefaultDispatchQueue(), execute body: (ErrorProtocol) throws -> T) -> Promise { fatalError() }

//MARK: disallow returning `Promise?`

    @available(*, unavailable, message: "unwrap the promise")
    public func then<U>(on: DispatchQueue = PMKDefaultDispatchQueue(), execute body: (T) throws -> Promise<U>?) -> Promise<U> { fatalError() }


    @available(*, unavailable, message: "unwrap the promise")
    public func recover(on: DispatchQueue = PMKDefaultDispatchQueue(), execute body: (ErrorProtocol) throws -> Promise?) -> Promise { fatalError() }
}

extension Promise: CustomStringConvertible {
    public var description: String {
        return "Promise: \(state)"
    }
}

/**
 Judicious use of `firstly` *may* make chains more readable.

 Compare:

     NSURLSession.GET(url1).then {
         NSURLSession.GET(url2)
     }.then {
         NSURLSession.GET(url3)
     }

 With:

     firstly {
         NSURLSession.GET(url1)
     }.then {
         NSURLSession.GET(url2)
     }.then {
         NSURLSession.GET(url3)
     }s
 */
public func firstly<T>(execute body: @noescape () throws -> Promise<T>) -> Promise<T> {
    do {
        return try body()
    } catch {
        return Promise.resolved(error: error)
    }
}

@available(*, unavailable, message: "instead of returning the error; throw")
public func firstly<T: ErrorProtocol>(execute body: @noescape () throws -> T) -> Promise<T> { fatalError() }


/**
 Used by `tap()`
 - remark: Same as `Resolution<T>` but without the associated `ErrorConsumptionToken`.
*/
public enum Result<T> {
    case fulfilled(T)
    case rejected(ErrorProtocol)

    private init(_ resolution: Resolution<T>) {
        switch resolution {
        case .fulfilled(let value):
            self = .fulfilled(value)
        case .rejected(let error, _):
            self = .rejected(error)
        }
    }
}
