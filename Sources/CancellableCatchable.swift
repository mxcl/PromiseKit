import Dispatch

/// Provides `catch` and `recover` to your object that conforms to `CancellableThenable`
public protocol CancellableCatchMixin: CancellableThenable {
    /// Type of the delegate `catchable`
    associatedtype C: CatchMixin

    /// Delegate `catchable` for this CancellablePromise
    var catchable: C { get }
}

public extension CancellableCatchMixin {
    /**
     The provided closure executes when this cancellable promise rejects.
     
     Rejecting a promise cascades: rejecting all subsequent promises (unless
     recover is invoked) thus you will typically place your catch at the end
     of a chain. Often utility promises will not have a catch, instead
     delegating the error handling to the caller.
     
     - Parameter on: The dispatcher that executes the provided closure.
     - Parameter policy: The default policy does not execute your handler for cancellation errors.
     - Parameter execute: The handler to execute if this promise is rejected.
     - Returns: A promise finalizer.
     - SeeAlso: [Cancellation](https://github.com/mxcl/PromiseKit/blob/master/Documentation/CommonPatterns.md#cancellation)
     */
    @discardableResult
    func `catch`(on: Dispatcher = conf.D.return, policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(Error) -> Void) -> CancellableFinalizer {
        return CancellableFinalizer(self.catchable.catch(on: on, policy: policy, body), cancel: self.cancelContext)
    }
}

/**
 Cancellable finalizer returned from `catch`.  Use `finally` to specify a code block that executes when the promise chain resolves.
 */
public class CancellableFinalizer {
    let pmkFinalizer: PMKFinalizer

    /// The CancelContext associated with this finalizer
    public let cancelContext: CancelContext
    
    init(_ pmkFinalizer: PMKFinalizer, cancel: CancelContext) {
        self.pmkFinalizer = pmkFinalizer
        self.cancelContext = cancel
    }
    
    /// `finally` is the same as `ensure`, but it is not chainable
    @discardableResult
    public func finally(on: Dispatcher = conf.D.return, _ body: @escaping () -> Void) -> CancelContext {
        pmkFinalizer.finally(on: on, body)
        return cancelContext
    }
    
    /**
     Cancel all members of the promise chain and their associated asynchronous operations.

     - Parameter error: Specifies the cancellation error to use for the cancel operation, defaults to `PMKError.cancelled`
     */
    public func cancel(with error: Error = PMKError.cancelled) {
        cancelContext.cancel(with: error)
    }
    
    /**
     True if all members of the promise chain have been successfully cancelled, false otherwise.
     */
    public var isCancelled: Bool {
        return cancelContext.isCancelled
    }
    
    /**
     True if `cancel` has been called on the CancelContext associated with this promise, false otherwise.  `cancelAttempted` will be true if `cancel` is called on any promise in the chain.
     */
    public var cancelAttempted: Bool {
        return cancelContext.cancelAttempted
    }
    
    /**
     The cancellation error generated when the promise is cancelled, or `nil` if not cancelled.
     */
    public var cancelledError: Error? {
        return cancelContext.cancelledError
    }
}

public extension CancellableCatchMixin {
    /**
     The provided closure executes when this cancellable promise rejects.
     
     Unlike `catch`, `recover` continues the chain.
     Use `recover` in circumstances where recovering the chain from certain errors is a possibility. For example:

         let context = firstly {
             CLLocationManager.requestLocation()
         }.recover { error in
             guard error == CLError.unknownLocation else { throw error }
             return .value(CLLocation.chicago)
         }.cancelContext
     
         //…
     
         context.cancel()
     
     - Parameter on: The dispatcher that executes the provided closure.
     - Parameter body: The handler to execute if this promise is rejected.
     - SeeAlso: [Cancellation](https://github.com/mxcl/PromiseKit/blob/master/Documentation/CommonPatterns.md#cancellation)
     */
    func recover<V: CancellableThenable>(on: Dispatcher = conf.D.map, policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(Error) throws -> V) -> CancellablePromise<C.T> where V.U.T == C.T {
        
        let cancelItemList = CancelItemList()

        let cancelBody = { (error: Error) throws -> V.U in
            _ = self.cancelContext.removeItems(self.cancelItemList, clearList: true)
            let rval = try body(error)
            if policy == .allErrors {
                self.cancelContext.recover()
            }
            self.cancelContext.append(context: rval.cancelContext, thenableCancelItemList: cancelItemList)
            return rval.thenable
        }
        
        let promise = self.catchable.recover(on: on, policy: policy, cancelBody)
        if thenable.result != nil && policy == .allErrors {
            self.cancelContext.recover()
        }
        return CancellablePromise(promise: promise, context: self.cancelContext, cancelItemList: cancelItemList)
    }
    
    /**
     The provided closure executes when this cancellable promise rejects.
     
     Unlike `catch`, `recover` continues the chain.
     Use `recover` in circumstances where recovering the chain from certain errors is a possibility. For example:

         let context = firstly {
             CLLocationManager.requestLocation()
         }.cancellize().recover { error in
             guard error == CLError.unknownLocation else { throw error }
             return .value(CLLocation.chicago)
         }.cancelContext
     
         //…
     
         context.cancel()
     
     - Parameter on: The dispatcher that executes the provided closure.
     - Parameter body: The handler to execute if this promise is rejected.
     - SeeAlso: [Cancellation](https://github.com/mxcl/PromiseKit/blob/master/Documentation/CommonPatterns.md#cancellation)
     - Note: Methods with the `cancellable` prefix create a new CancellablePromise, and those without the `cancellable` prefix accept an existing CancellablePromise.
     */
    func recover<V: Thenable>(on: Dispatcher = conf.D.map, policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(Error) throws -> V) -> CancellablePromise<C.T> where V.T == C.T {
        
        let cancelBody = { (error: Error) throws -> V in
            _ = self.cancelContext.removeItems(self.cancelItemList, clearList: true)
            let rval = try body(error)
            if policy == .allErrors {
                self.cancelContext.recover()
            }
            return rval
        }
        
        let promise = self.catchable.recover(on: on, policy: policy, cancelBody)
        if thenable.result != nil && policy == .allErrors {
            self.cancelContext.recover()
        }
        let cancellablePromise = CancellablePromise(promise: promise, context: self.cancelContext)
        if let cancellable = promise.cancellable {
            self.cancelContext.append(cancellable: cancellable, reject: promise.rejectIfCancelled, thenable: cancellablePromise)
        }
        return cancellablePromise
    }

    /**
     The provided closure executes when this cancellable promise resolves, whether it rejects or not.
     
         let context = firstly {
             UIApplication.shared.networkActivityIndicatorVisible = true
             //…  returns a cancellable promise
         }.done {
             //…
         }.ensure {
             UIApplication.shared.networkActivityIndicatorVisible = false
         }.catch {
             //…
         }.cancelContext
     
         //…
     
         context.cancel()

     - Parameter on: The dispatcher that executes the provided closure.
     - Parameter body: The closure that executes when this promise resolves.
     - Returns: A new promise, resolved with this promise’s resolution.
     */
    func ensure(on: Dispatcher = conf.D.return, _ body: @escaping () -> Void) -> CancellablePromise<C.T> {
        let rp = CancellablePromise<C.T>.pending()
        rp.promise.cancelContext = self.cancelContext
        self.catchable.pipe { result in
            on.dispatch {
                body()
                switch result {
                case .success(let value):
                    if let error = self.cancelContext.cancelledError {
                        rp.resolver.reject(error)
                    } else {
                        rp.resolver.fulfill(value)
                    }
                case .failure(let error):
                    rp.resolver.reject(error)
                }
            }
        }
        return rp.promise
    }
    
    /**
     The provided closure executes when this cancellable promise resolves, whether it rejects or not.
     The chain waits on the returned `CancellablePromise<Void>`.

         let context = firstly {
             setup() // returns a cancellable promise
         }.done {
             //…
         }.ensureThen {
             teardown()  // -> CancellablePromise<Void>
         }.catch {
             //…
         }.cancelContext
     
         //…
     
         context.cancel()

     - Parameter on: The dispatcher that executes the provided closure.
     - Parameter body: The closure that executes when this promise resolves.
     - Returns: A new promise, resolved with this promise’s resolution.
     */
    func ensureThen(on: Dispatcher = conf.D.return, _ body: @escaping () -> CancellablePromise<Void>) -> CancellablePromise<C.T> {
        let rp = CancellablePromise<C.T>.pending()
        rp.promise.cancelContext = cancelContext
        self.catchable.pipe { result in
            on.dispatch {
                let rv = body()
                rp.promise.appendCancelContext(from: rv)
                
                rv.done {
                    switch result {
                    case .success(let value):
                        if let error = self.cancelContext.cancelledError {
                            rp.resolver.reject(error)
                        } else {
                            rp.resolver.fulfill(value)
                        }
                    case .failure(let error):
                        rp.resolver.reject(error)
                    }
                }.catch(policy: .allErrors) {
                    rp.resolver.reject($0)
                }
            }
        }
        return rp.promise
    }
    
    /**
     Consumes the Swift unused-result warning.
     - Note: You should `catch`, but in situations where you know you don’t need a `catch`, `cauterize` makes your intentions clear.
     */
    @discardableResult
    func cauterize() -> CancellableFinalizer {
        return self.catch(policy: .allErrors) {
            Swift.print("PromiseKit:cauterized-error:", $0)
        }
    }
}

public extension CancellableCatchMixin where C.T == Void {
    /**
     The provided closure executes when this cancellable promise rejects.
     
     This variant of `recover` ensures that no error is thrown from the handler and allows specifying a catch policy.
     
     - Parameter on: The dispatcher that executes the provided closure.
     - Parameter body: The handler to execute if this promise is rejected.
     - SeeAlso: [Cancellation](https://github.com/mxcl/PromiseKit/blob/master/Documentation/CommonPatterns.md#cancellation)
     */
    func recover(on: Dispatcher = conf.D.map, policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(Error) throws -> Void) -> CancellablePromise<Void> {
        let cancelBody = { (error: Error) throws -> Void in
            _ = self.cancelContext.removeItems(self.cancelItemList, clearList: true)
            try body(error)
            if policy == .allErrors {
                self.cancelContext.recover()
            }
        }
        
        let promise = self.catchable.recover(on: on, policy: policy, cancelBody)
        if thenable.result != nil && policy == .allErrors {
            self.cancelContext.recover()
        }
        return CancellablePromise(promise: promise, context: self.cancelContext)
    }
}
