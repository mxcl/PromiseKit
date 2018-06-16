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
}
