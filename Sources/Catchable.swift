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
     
     - Parameter on: The dispatcher that executes the provided closure.
     - Parameter policy: The default policy does not execute your handler for cancellation errors.
     - Parameter body: The handler to execute if this promise is rejected.
     - Returns: A promise finalizer.
     - SeeAlso: [Cancellation](https://github.com/mxcl/PromiseKit/blob/master/Documents/CommonPatterns.md#cancellation)
     */
    @discardableResult
    func `catch`(on: Dispatcher = conf.D.return, policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(Error) -> Void) -> PMKFinalizer {
        let finalizer = PMKFinalizer()
        pipe {
            switch $0 {
            case .failure(let error):
                guard policy == .allErrors || !error.isCancelled else {
                    fallthrough
                }
                on.dispatch {
                    body(error)
                    finalizer.pending.resolve(())
                }
            case .success:
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

     - Parameter only: The specific error to be caught and handled (e.g., `PMKError.emptySequence`).
     - Parameter on: The dispatcher that executes the provided closure.
     - Parameter body: The handler to execute if this promise is rejected with the provided error.
     - Returns: A promise finalizer that accepts additional `catch` clauses.
     - Note: Since this method handles only specific errors, supplying a `CatchPolicy` is unsupported.
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     */
    func `catch`<E: Swift.Error>(_ only: E, on: Dispatcher = conf.D.return, _ body: @escaping() -> Void) -> PMKCascadingFinalizer where E: Equatable {
        let finalizer = PMKCascadingFinalizer()
        pipe {
            switch $0 {
            case .failure(let error as E) where error == only:
                on.dispatch {
                    body()
                    finalizer.pending.resolver.fulfill(())
                }
            case .failure(let error):
                finalizer.pending.resolver.reject(error)
            case .success:
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

     - Parameter only: The error type to be caught and handled (e.g., `PMKError`).
     - Parameter on: The dispatcher that executes the provided closure.
     - Parameter policy: A `CatchPolicy` that further constrains the errors this handler will see. E.g., if
         you are receiving `PMKError` errors, do you want to see even those that result from cancellation?
     - Parameter body: The handler to execute if this promise is rejected with the provided error type.
     - Returns: A promise finalizer that accepts additional `catch` clauses.
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     */
    func `catch`<E: Swift.Error>(_ only: E.Type, on: Dispatcher = conf.D.return, policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(E) -> Void) -> PMKCascadingFinalizer {
        let finalizer = PMKCascadingFinalizer()
        pipe {
            switch $0 {
            case .failure(let error as E):
                guard policy == .allErrors || !error.isCancelled else {
                    return finalizer.pending.resolver.reject(error)
                }
                on.dispatch {
                    body(error)
                    finalizer.pending.resolver.fulfill(())
                }
            case .failure(let error):
                finalizer.pending.resolver.reject(error)
            case .success:
                finalizer.pending.resolver.fulfill(())
            }
        }
        return finalizer
    }
}

public class PMKFinalizer {
    let pending = Guarantee<Void>.pending()

    /// `finally` is the same as `ensure`, but it is not chainable
    public func finally(on: Dispatcher = conf.D.return, _ body: @escaping () -> Void) {
        pending.guarantee.done(on: on) {
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

     - Parameter on: The dispatcher that executes the provided closure.
     - Parameter policy: The default policy does not execute your handler for cancellation errors.
     - Parameter body: The handler to execute if this promise is rejected.
     - Returns: A promise finalizer.
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     */
    @discardableResult
    public func `catch`(on: Dispatcher = conf.D.return, policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(Error) -> Void) -> PMKFinalizer {
        return pending.promise.catch(on: on, policy: policy) {
            body($0)
        }
    }

    /**
     The provided closure executes when this promise rejects with the specific error passed in. A final `catch` is still required at the end of the chain.

     Rejecting a promise cascades: rejecting all subsequent promises (unless
     recover is invoked) thus you will typically place your catch at the end
     of a chain. Often utility promises will not have a catch, instead
     delegating the error handling to the caller.

     - Parameter only: The specific error to be caught and handled (e.g., `PMKError.emptySequence`).
     - Parameter on: The dispatcher that executes the provided closure.
     - Parameter body: The handler to execute if this promise is rejected with the provided error.
     - Returns: A promise finalizer that accepts additional `catch` clauses.
     - Note: Since this method handles only specific errors, supplying a `CatchPolicy` is unsupported.
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     */
    public func `catch`<E: Swift.Error>(_ only: E, on: Dispatcher = conf.D.return, _ body: @escaping() -> Void) -> PMKCascadingFinalizer where E: Equatable {
        return pending.promise.catch(only, on: on) {
            body()
        }
    }

    /**
     The provided closure executes when this promise rejects with an error of the type passed in. A final `catch` is still required at the end of the chain.

     Rejecting a promise cascades: rejecting all subsequent promises (unless
     recover is invoked) thus you will typically place your catch at the end
     of a chain. Often utility promises will not have a catch, instead
     delegating the error handling to the caller.

     - Parameter only: The error type to be caught and handled (e.g., `PMKError`).
     - Parameter on: The dispatcher that executes the provided closure.
     - Parameter body: The handler to execute if this promise is rejected with the provided error type.
     - Returns: A promise finalizer that accepts additional `catch` clauses.
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     */
    public func `catch`<E: Swift.Error>(_ only: E.Type, on: Dispatcher = conf.D.return, policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(E) -> Void) -> PMKCascadingFinalizer {
        return pending.promise.catch(only, on: on, policy: policy) {
            body($0)
        }
    }
}

public extension CatchMixin {
    
    /**
     The provided closure executes when this promise rejects.
     
     Unlike `catch`, `recover` continues the chain. It can return a replacement promise or rethrow.
     Use `recover` in circumstances where recovering the chain from certain errors is a possibility. For example:

         firstly {
             CLLocationManager.requestLocation()
         }.recover { error in
             guard error == CLError.unknownLocation else { throw error }
             return .value(CLLocation.chicago)
         }
     
     - Parameter on: The dispatcher that executes the provided closure.
     - Parameter policy: The default policy does not execute your handler for cancellation errors.
     - Parameter body: The handler to execute if this promise is rejected.
     - SeeAlso: [Cancellation](https://github.com/mxcl/PromiseKit/blob/master/Documents/CommonPatterns.md#cancellation)
     */
    func recover<U: Thenable>(on: Dispatcher = conf.D.map, policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(Error) throws -> U) -> Promise<T> where U.T == T {
        let rp = Promise<U.T>(.pending)
        pipe {
            switch $0 {
            case .success(let value):
                rp.box.seal(.success(value))
            case .failure(let error):
                if policy == .allErrors || !error.isCancelled {
                    on.dispatch {
                        do {
                            let rv = try body(error)
                            guard rv !== rp else { throw PMKError.returnedSelf }
                            rv.pipe(to: rp.box.seal)
                        } catch {
                            rp.box.seal(.failure(error))
                        }
                    }
                } else {
                    rp.box.seal(.failure(error))
                }
            }
        }
        return rp
    }

    /**
     The provided closure executes when this promise rejects with the specific error passed in.

     Unlike `catch`, `recover` continues the chain. It can return a replacement promise or rethrow.
     Use `recover` in circumstances where recovering the chain from certain errors is a possibility. For example:

         firstly {
             CLLocationManager.requestLocation()
         }.recover(CLError.unknownLocation) {
             return .value(CLLocation.chicago)
         }

     - Parameter only: The specific error to be recovered (e.g., `PMKError.emptySequence`)
     - Parameter on: The dispatcher that executes the provided closure.
     - Parameter body: The handler to execute if this promise is rejected with the provided error.
     - Note: Since this method recovers only specific errors, supplying a `CatchPolicy` is unsupported.
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     */
    func recover<U: Thenable, E: Swift.Error>(_ only: E, on: Dispatcher = conf.D.map, _ body: @escaping() -> U) -> Promise<T> where U.T == T, E: Equatable {
        let rp = Promise<U.T>(.pending)
        pipe {
            switch $0 {
            case .success(let value):
                rp.box.seal(.success(value))
            case .failure(let error as E) where error == only:
                on.dispatch {
                    do {
                        let rv = body()
                        guard rv !== rp else { throw PMKError.returnedSelf }
                        rv.pipe(to: rp.box.seal)
                    } catch {
                        rp.box.seal(.failure(error))
                    }
                }
            case .failure(let error):
                rp.box.seal(.failure(error))
            }
        }
        return rp
    }

    /**
     The provided closure executes when this promise rejects with an error of the type passed in.

     Unlike `catch`, `recover` continues the chain. It can return a replacement promise or rethrow.
     Use `recover` in circumstances where recovering the chain from certain errors is a possibility. For example:

         firstly {
             API.fetchData()
         }.recover(FetchError.self) { error in
             guard case .missingImage(let partialData) = error else { throw error }
             //…
             return .value(dataWithDefaultImage)
         }

     - Parameter only: The error type to be recovered (e.g., `PMKError`).
     - Parameter on: The dispatcher that executes the provided closure.
     - Parameter policy: The default policy does not execute your handler for cancellation errors.
     - Parameter body: The handler to execute if this promise is rejected with the provided error type.
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     */
    func recover<U: Thenable, E: Swift.Error>(_ only: E.Type, on: Dispatcher = conf.D.map, policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(E) throws -> U) -> Promise<T> where U.T == T {
        let rp = Promise<U.T>(.pending)
        pipe {
            switch $0 {
            case .success(let value):
                rp.box.seal(.success(value))
            case .failure(let error as E):
                if policy == .allErrors || !error.isCancelled {
                    on.dispatch {
                        do {
                            let rv = try body(error)
                            guard rv !== rp else { throw PMKError.returnedSelf }
                            rv.pipe(to: rp.box.seal)
                        } catch {
                            rp.box.seal(.failure(error))
                        }
                    }
                } else {
                    rp.box.seal(.failure(error))
                }
            case .failure(let error):
                rp.box.seal(.failure(error))
            }
        }
        return rp
    }

    /**
     The provided closure executes when this promise rejects.
     This variant of `recover` requires the handler to return a Guarantee; your closure cannot `throw`.
     
     It is logically impossible for this variant to accept a `catchPolicy`. All errors will be presented
     to your closure for processing.
     
     - Parameter on: The dispatcher that executes the provided closure.
     - Parameter body: The handler to execute if this promise is rejected.
     - SeeAlso: [Cancellation](https://github.com/mxcl/PromiseKit/blob/master/Documents/CommonPatterns.md#cancellation)
     */
    @discardableResult
    func recover(on: Dispatcher = conf.D.map, _ body: @escaping(Error) -> Guarantee<T>) -> Guarantee<T> {
        let rg = Guarantee<T>(.pending)
        pipe {
            switch $0 {
            case .success(let value):
                rg.box.seal(value)
            case .failure(let error):
                on.dispatch {
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
     
     - Parameter on: The dispatcher that executes the provided closure.
     - Parameter body: The closure that executes when this promise resolves.
     - Returns: A new promise, resolved with this promise’s resolution.
     */
    func ensure(on: Dispatcher = conf.D.return, _ body: @escaping () -> Void) -> Promise<T> {
        let rp = Promise<T>(.pending)
        pipe { result in
            on.dispatch {
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

     - Parameter on: The dispatcher that executes the provided closure.
     - Parameter body: The closure that executes when this promise resolves.
     - Returns: A new promise, resolved with this promise’s resolution.
     */
    func ensureThen(on: Dispatcher = conf.D.return, _ body: @escaping () -> Guarantee<Void>) -> Promise<T> {
        let rp = Promise<T>(.pending)
        pipe { result in
            on.dispatch {
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
            conf.logHandler(.cauterized($0))
        }
    }
}


public extension CatchMixin where T == Void {
    
    /**
     The provided closure executes when this promise rejects.
     
     This variant of `recover` is specialized for `Void` promises and de-errors your chain,
     returning a `Guarantee`. Thus, you cannot `throw` and you must handle all error types,
     including cancellation.
     
     - Parameter on: The dispatcher that executes the provided closure.
     - Parameter body: The handler to execute if this promise is rejected.
     - SeeAlso: [Cancellation](https://github.com/mxcl/PromiseKit/blob/master/Documents/CommonPatterns.md#cancellation)
     */
    @discardableResult
    func recover(on: Dispatcher = conf.D.map, _ body: @escaping(Error) -> Void) -> Guarantee<Void> {
        let rg = Guarantee<Void>(.pending)
        pipe {
            switch $0 {
            case .success:
                rg.box.seal(())
            case .failure(let error):
                on.dispatch {
                    body(error)
                    rg.box.seal(())
                }
            }
        }
        return rg
    }

    /**
     The provided closure executes when this promise rejects.
     
     This variant of `recover` ensures that no error is thrown from the handler
     and allows you to specify a catch policy.
     
     - Parameter on: The dispatcher that executes the provided closure.
     - Parameter body: The handler to execute if this promise is rejected.
     - SeeAlso: [Cancellation](https://github.com/mxcl/PromiseKit/blob/master/Documents/CommonPatterns.md#cancellation)
     */
    func recover(on: Dispatcher = conf.D.map, policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(Error) throws -> Void) -> Promise<Void> {
        let rg = Promise<Void>(.pending)
        pipe {
            switch $0 {
            case .success:
                rg.box.seal(.success(()))
            case .failure(let error):
                if policy == .allErrors || !error.isCancelled {
                    on.dispatch {
                        do {
                            rg.box.seal(.success(try body(error)))
                        } catch {
                            rg.box.seal(.failure(error))
                        }
                    }
                } else {
                    rg.box.seal(.failure(error))
                }
            }
        }
        return rg
    }

    /**
     The provided closure executes when this promise rejects with the specific error passed in.
    
     Unlike `catch`, `recover` continues the chain. It can return a replacement promise or rethrow.
     Use `recover` in circumstances where recovering the chain from certain errors is a possibility.
 
     - Parameter only: The specific error to be recovered (e.g., `PMKError.emptySequence`)
     - Parameter on: The dispatcher that executes the provided closure.
     - Parameter body: The handler to execute if this promise is rejected with the provided error.
     - Note: Since this method recovers only specific errors, supplying a `CatchPolicy` is unsupported.
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     */
    func recover<E: Swift.Error>(_ only: E, on: Dispatcher = conf.D.map, _ body: @escaping() -> Void) -> Promise<Void> where E: Equatable {
        let rp = Promise<Void>(.pending)
        pipe {
            switch $0 {
            case .success:
                rp.box.seal(.success(()))
            case .failure(let error as E) where error == only:
                on.dispatch {
                    body()
                    rp.box.seal(.success(()))
                }
            case .failure(let error):
                rp.box.seal(.failure(error))
            }
        }
        return rp
    }

    /**
     The provided closure executes when this promise rejects with an error of the type passed in.
     
     Unlike `catch`, `recover` continues the chain. It can return a replacement promise or rethrow.
     Use `recover` in circumstances where recovering the chain from certain errors is a possibility.
     
     - Parameter only: The error type to be recovered (e.g., `PMKError`).
     - Parameter on: The dispatcher that executes the provided closure.
     - Parameter policy: The default policy does not execute your handler for cancellation errors.
     - Parameter body: The handler to execute if this promise is rejected with the provided error type.
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     */
    func recover<E: Swift.Error>(_ only: E.Type, on: Dispatcher = conf.D.map, policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(E) throws -> Void) -> Promise<Void> {
        let rp = Promise<Void>(.pending)
        pipe {
            switch $0 {
            case .success:
                rp.box.seal(.success(()))
            case .failure(let error as E):
                if policy == .allErrors || !error.isCancelled {
                    on.dispatch {
                        do {
                            rp.box.seal(.success(try body(error)))
                        } catch {
                            rp.box.seal(.failure(error))
                        }
                    }
                } else {
                    rp.box.seal(.failure(error))
                }
            case .failure(let error):
                rp.box.seal(.failure(error))
            }
        }
        return rp
    }
}
