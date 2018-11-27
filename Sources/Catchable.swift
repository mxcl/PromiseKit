import Dispatch

/// Provides `catch` and `recover` to your object that conforms to `Thenable`
public protocol CatchMixin: Thenable
{}

public extension CatchMixin {
    
    /**
     The provided closure executes when this promise rejects.
     
     Rejecting a promise cascades: rejecting all subsequent promises (unless
     recover is invoked) thus you will typically place your catch at the end
     of a chain. Often utility promises will not have a catch, instead
     delegating the error handling to the caller.
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter policy: The default policy does not execute your handler for cancellation errors.
     - Parameter execute: The handler to execute if this promise is rejected.
     - Returns: A promise finalizer.
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     */
    @discardableResult
    func `catch`(on: DispatchQueue? = conf.Q.return, flags: DispatchWorkItemFlags? = nil, policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(Error) -> Void) -> PMKFinalizer {
        let finalizer = PMKFinalizer()
        pipe {
            switch $0 {
            case .rejected(let error):
                guard policy == .allErrors || !error.isCancelled else {
                    fallthrough
                }
                on.async(flags: flags) {
                    body(error)
                    finalizer.pending.resolve(())
                }
            case .fulfilled:
                finalizer.pending.resolve(())
            }
        }
        return finalizer
    }

    /**
     The provided closure executes when this promise rejects with the specific error passed in. A final `catch` is still required at the end of the chain.

     Rejecting a promise cascades: rejecting all subsequent promises (unless
     recover is invoked) thus you will typically place your catch at the end
     of a chain. Often utility promises will not have a catch, instead
     delegating the error handling to the caller.

     - Parameter only: The specific error to be caught and handled.
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter execute: The handler to execute if this promise is rejected with the provided error.
     - Note: Since this method handles only specific errors, supplying a `CatchPolicy` is unsupported. You can instead specify e.g. your cancellable error.
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     */
    func catchOnly<E: Swift.Error>(_ only: E, on: DispatchQueue? = conf.Q.return, flags: DispatchWorkItemFlags? = nil, _ body: @escaping() -> Void) -> PMKCascadingFinalizer where E: Equatable {
        let finalizer = PMKCascadingFinalizer()
        pipe {
            switch $0 {
            case .rejected(let error as E) where error == only:
                on.async(flags: flags) {
                    body()
                    finalizer.pending.resolver.fulfill(())
                }
            case .rejected(let error):
                finalizer.pending.resolver.reject(error)
            case .fulfilled:
                finalizer.pending.resolver.fulfill(())
            }
        }
        return finalizer
    }

    /**
     The provided closure executes when this promise rejects with an error of the type passed in. A final `catch` is still required at the end of the chain.

     Rejecting a promise cascades: rejecting all subsequent promises (unless
     recover is invoked) thus you will typically place your catch at the end
     of a chain. Often utility promises will not have a catch, instead
     delegating the error handling to the caller.

     - Parameter only: The error type to be caught and handled.
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter execute: The handler to execute if this promise is rejected with the provided error type.
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     */
    func catchOnly<E: Swift.Error>(_ only: E.Type, on: DispatchQueue? = conf.Q.return, flags: DispatchWorkItemFlags? = nil, policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(E) -> Void) -> PMKCascadingFinalizer {
        let finalizer = PMKCascadingFinalizer()
        pipe {
            switch $0 {
            case .rejected(let error as E):
                guard policy == .allErrors || !error.isCancelled else {
                    return finalizer.pending.resolver.reject(error)
                }
                on.async(flags: flags) {
                    body(error)
                    finalizer.pending.resolver.fulfill(())
                }
            case .rejected(let error):
                finalizer.pending.resolver.reject(error)
            case .fulfilled:
                finalizer.pending.resolver.fulfill(())
            }
        }
        return finalizer
    }
}

public class PMKFinalizer {
    let pending = Guarantee<Void>.pending()

    /// `finally` is the same as `ensure`, but it is not chainable
    public func finally(on: DispatchQueue? = conf.Q.return, flags: DispatchWorkItemFlags? = nil, _ body: @escaping () -> Void) {
        pending.guarantee.done(on: on, flags: flags) {
            body()
        }
    }
}

public class PMKCascadingFinalizer {
    let pending = Promise<Void>.pending()

    /**
     The provided closure executes when this promise rejects.

     Rejecting a promise cascades: rejecting all subsequent promises (unless
     recover is invoked) thus you will typically place your catch at the end
     of a chain. Often utility promises will not have a catch, instead
     delegating the error handling to the caller.

     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter policy: The default policy does not execute your handler for cancellation errors.
     - Parameter execute: The handler to execute if this promise is rejected.
     - Returns: A promise finalizer.
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     */
    @discardableResult
    public func `catch`(on: DispatchQueue? = conf.Q.return, flags: DispatchWorkItemFlags? = nil, policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(Error) -> Void) -> PMKFinalizer {
        return pending.promise.catch(on: on, flags: flags, policy: policy) {
            body($0)
        }
    }

    /**
     The provided closure executes when this promise rejects with the specific error passed in. A final `catch` is still required at the end of the chain.

     Rejecting a promise cascades: rejecting all subsequent promises (unless
     recover is invoked) thus you will typically place your catch at the end
     of a chain. Often utility promises will not have a catch, instead
     delegating the error handling to the caller.

     - Parameter only: The specific error to be caught and handled.
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter execute: The handler to execute if this promise is rejected with the provided error.
     - Note: Since this method handles only specific errors, supplying a `CatchPolicy` is unsupported. You can instead specify e.g. your cancellable error.
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     */
    public func catchOnly<E: Swift.Error>(_ only: E, on: DispatchQueue? = conf.Q.return, flags: DispatchWorkItemFlags? = nil, _ body: @escaping() -> Void) -> PMKCascadingFinalizer where E: Equatable {
        return pending.promise.catchOnly(only, on: on, flags: flags) {
            body()
        }
    }

    /**
     The provided closure executes when this promise rejects with an error of the type passed in. A final `catch` is still required at the end of the chain.

     Rejecting a promise cascades: rejecting all subsequent promises (unless
     recover is invoked) thus you will typically place your catch at the end
     of a chain. Often utility promises will not have a catch, instead
     delegating the error handling to the caller.

     - Parameter only: The error type to be caught and handled.
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter execute: The handler to execute if this promise is rejected with the provided error type.
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     */
    public func catchOnly<E: Swift.Error>(_ only: E.Type, on: DispatchQueue? = conf.Q.return, flags: DispatchWorkItemFlags? = nil, policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(E) -> Void) -> PMKCascadingFinalizer {
        return pending.promise.catchOnly(only, on: on, flags: flags, policy: policy) {
            body($0)
        }
    }
}

public extension CatchMixin {
    
    /**
     The provided closure executes when this promise rejects.
     
     Unlike `catch`, `recover` continues the chain.
     Use `recover` in circumstances where recovering the chain from certain errors is a possibility. For example:

         firstly {
             CLLocationManager.requestLocation()
         }.recover { error in
             guard error == CLError.unknownLocation else { throw error }
             return .value(CLLocation.chicago)
         }
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The handler to execute if this promise is rejected.
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     */
    func recover<U: Thenable>(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(Error) throws -> U) -> Promise<T> where U.T == T {
        let rp = Promise<U.T>(.pending)
        pipe {
            switch $0 {
            case .fulfilled(let value):
                rp.box.seal(.fulfilled(value))
            case .rejected(let error):
                if policy == .allErrors || !error.isCancelled {
                    on.async(flags: flags) {
                        do {
                            let rv = try body(error)
                            guard rv !== rp else { throw PMKError.returnedSelf }
                            rv.pipe(to: rp.box.seal)
                        } catch {
                            rp.box.seal(.rejected(error))
                        }
                    }
                } else {
                    rp.box.seal(.rejected(error))
                }
            }
        }
        return rp
    }

    /**
     The provided closure executes when this promise rejects with the specific error passed in.

     Unlike `catch`, `recover` continues the chain.
     Use `recover` in circumstances where recovering the chain from certain errors is a possibility. For example:

         firstly {
             CLLocationManager.requestLocation()
         }.recoverOnly(CLError.unknownLocation) {
             return .value(CLLocation.chicago)
         }

     - Parameter only: The specific error to be recovered.
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The handler to execute if this promise is rejected with the provided error.
     - Note: Since this method recovers only specific errors, supplying a `CatchPolicy` is unsupported. You can instead specify e.g. your cancellable error.
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     */
    func recoverOnly<U: Thenable, E: Swift.Error>(_ only: E, on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, _ body: @escaping() -> U) -> Promise<T> where U.T == T, E: Equatable {
        let rp = Promise<U.T>(.pending)
        pipe {
            switch $0 {
            case .fulfilled(let value):
                rp.box.seal(.fulfilled(value))
            case .rejected(let error as E) where error == only:
                on.async(flags: flags) {
                    do {
                        let rv = body()
                        guard rv !== rp else { throw PMKError.returnedSelf }
                        rv.pipe(to: rp.box.seal)
                    } catch {
                        rp.box.seal(.rejected(error))
                    }
                }
            case .rejected(let error):
                rp.box.seal(.rejected(error))
            }
        }
        return rp
    }

    /**
     The provided closure executes when this promise rejects with an error of the type passed in.

     Unlike `catch`, `recover` continues the chain.
     Use `recover` in circumstances where recovering the chain from certain errors is a possibility. For example:

         firstly {
             API.fetchData()
         }.recoverOnly(FetchError.self) { error in
             guard case .missingImage(let partialData) = error else { throw error }
             //…
             return .value(dataWithDefaultImage)
         }

     - Parameter only: The error type to be recovered.
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The handler to execute if this promise is rejected with the provided error type.
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     */
    func recoverOnly<U: Thenable, E: Swift.Error>(_ only: E.Type, on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(E) throws -> U) -> Promise<T> where U.T == T {
        let rp = Promise<U.T>(.pending)
        pipe {
            switch $0 {
            case .fulfilled(let value):
                rp.box.seal(.fulfilled(value))
            case .rejected(let error as E):
                if policy == .allErrors || !error.isCancelled {
                    on.async(flags: flags) {
                        do {
                            let rv = try body(error)
                            guard rv !== rp else { throw PMKError.returnedSelf }
                            rv.pipe(to: rp.box.seal)
                        } catch {
                            rp.box.seal(.rejected(error))
                        }
                    }
                } else {
                    rp.box.seal(.rejected(error))
                }
            case .rejected(let error):
                rp.box.seal(.rejected(error))
            }
        }
        return rp
    }

    /**
     The provided closure executes when this promise rejects.
     This variant of `recover` requires the handler to return a Guarantee, thus it returns a Guarantee itself and your closure cannot `throw`.
     - Note it is logically impossible for this to take a `catchPolicy`, thus `allErrors` are handled.
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The handler to execute if this promise is rejected.
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     */
    @discardableResult
    func recover(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, _ body: @escaping(Error) -> Guarantee<T>) -> Guarantee<T> {
        let rg = Guarantee<T>(.pending)
        pipe {
            switch $0 {
            case .fulfilled(let value):
                rg.box.seal(value)
            case .rejected(let error):
                on.async(flags: flags) {
                    body(error).pipe(to: rg.box.seal)
                }
            }
        }
        return rg
    }

    /**
     The provided closure executes when this promise resolves, whether it rejects or not.
     
         firstly {
             UIApplication.shared.networkActivityIndicatorVisible = true
         }.done {
             //…
         }.ensure {
             UIApplication.shared.networkActivityIndicatorVisible = false
         }.catch {
             //…
         }
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The closure that executes when this promise resolves.
     - Returns: A new promise, resolved with this promise’s resolution.
     */
    func ensure(on: DispatchQueue? = conf.Q.return, flags: DispatchWorkItemFlags? = nil, _ body: @escaping () -> Void) -> Promise<T> {
        let rp = Promise<T>(.pending)
        pipe { result in
            on.async(flags: flags) {
                body()
                rp.box.seal(result)
            }
        }
        return rp
    }

    /**
     The provided closure executes when this promise resolves, whether it rejects or not.
     The chain waits on the returned `Guarantee<Void>`.

         firstly {
             setup()
         }.done {
             //…
         }.ensureThen {
             teardown()  // -> Guarante<Void>
         }.catch {
             //…
         }

     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The closure that executes when this promise resolves.
     - Returns: A new promise, resolved with this promise’s resolution.
     */
    func ensureThen(on: DispatchQueue? = conf.Q.return, flags: DispatchWorkItemFlags? = nil, _ body: @escaping () -> Guarantee<Void>) -> Promise<T> {
        let rp = Promise<T>(.pending)
        pipe { result in
            on.async(flags: flags) {
                body().done {
                    rp.box.seal(result)
                }
            }
        }
        return rp
    }



    /**
     Consumes the Swift unused-result warning.
     - Note: You should `catch`, but in situations where you know you don’t need a `catch`, `cauterize` makes your intentions clear.
     */
    @discardableResult
    func cauterize() -> PMKFinalizer {
        return self.catch {
            Swift.print("PromiseKit:cauterized-error:", $0)
        }
    }
}


public extension CatchMixin where T == Void {
    
    /**
     The provided closure executes when this promise rejects.
     
     This variant of `recover` is specialized for `Void` promises and de-errors your chain returning a `Guarantee`, thus you cannot `throw` and you must handle all errors including cancellation.
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The handler to execute if this promise is rejected.
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     */
    @discardableResult
    func recover(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, _ body: @escaping(Error) -> Void) -> Guarantee<Void> {
        let rg = Guarantee<Void>(.pending)
        pipe {
            switch $0 {
            case .fulfilled:
                rg.box.seal(())
            case .rejected(let error):
                on.async(flags: flags) {
                    body(error)
                    rg.box.seal(())
                }
            }
        }
        return rg
    }

    /**
     The provided closure executes when this promise rejects.
     
     This variant of `recover` ensures that no error is thrown from the handler and allows specifying a catch policy.
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The handler to execute if this promise is rejected.
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     */
    func recover(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(Error) throws -> Void) -> Promise<Void> {
        let rg = Promise<Void>(.pending)
        pipe {
            switch $0 {
            case .fulfilled:
                rg.box.seal(.fulfilled(()))
            case .rejected(let error):
                if policy == .allErrors || !error.isCancelled {
                    on.async(flags: flags) {
                        do {
                            rg.box.seal(.fulfilled(try body(error)))
                        } catch {
                            rg.box.seal(.rejected(error))
                        }
                    }
                } else {
                    rg.box.seal(.rejected(error))
                }
            }
        }
        return rg
    }

    /**
     The provided closure executes when this promise rejects with the specific error passed in.

     Unlike `catch`, `recover` continues the chain.
     Use `recover` in circumstances where recovering the chain from certain errors is a possibility.

     - Parameter only: The specific error to be recovered.
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The handler to execute if this promise is rejected with the provided error.
     - Note: Since this method recovers only specific errors, supplying a `CatchPolicy` is unsupported. You can instead specify e.g. your cancellable error.
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     */
    func recoverOnly<E: Swift.Error>(_ only: E, on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, _ body: @escaping() -> Void) -> Promise<Void> where E: Equatable {
        let rp = Promise<Void>(.pending)
        pipe {
            switch $0 {
            case .fulfilled:
                rp.box.seal(.fulfilled())
            case .rejected(let error as E) where error == only:
                on.async(flags: flags) {
                    body()
                    rp.box.seal(.fulfilled())
                }
            case .rejected(let error):
                rp.box.seal(.rejected(error))
            }
        }
        return rp
    }

    /**
     The provided closure executes when this promise rejects with an error of the type passed in.

     Unlike `catch`, `recover` continues the chain.
     Use `recover` in circumstances where recovering the chain from certain errors is a possibility.

     - Parameter only: The error type to be recovered.
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The handler to execute if this promise is rejected with the provided error type.
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     */
    func recoverOnly<E: Swift.Error>(_ only: E.Type, on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(E) throws -> Void) -> Promise<Void> {
        let rp = Promise<Void>(.pending)
        pipe {
            switch $0 {
            case .fulfilled:
                rp.box.seal(.fulfilled())
            case .rejected(let error as E):
                if policy == .allErrors || !error.isCancelled {
                    on.async(flags: flags) {
                        do {
                            try body(error)
                            rp.box.seal(.fulfilled())
                        } catch {
                            rp.box.seal(.rejected(error))
                        }
                    }
                } else {
                    rp.box.seal(.rejected(error))
                }
            case .rejected(let error):
                rp.box.seal(.rejected(error))
            }
        }
        return rp
    }
}
