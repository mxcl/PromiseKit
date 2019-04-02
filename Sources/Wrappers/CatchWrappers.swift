import Dispatch

public extension _PMKCatchWrappers {
    
    /**
     The provided closure executes when this promise rejects.
     
     Rejecting a promise cascades: rejecting all subsequent promises (unless
     recover is invoked) thus you will typically place your catch at the end
     of a chain. Often utility promises will not have a catch, instead
     delegating the error handling to the caller.
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter flags: `DispatchWorkItemFlags` to be applied when dispatching.
     - Parameter policy: The default policy does not execute your handler for cancellation errors.
     - Parameter body: The handler to execute if this promise is rejected.
     - Returns: A promise finalizer.
     - SeeAlso: [Cancellation](http://https://github.com/mxcl/PromiseKit/blob/master/Documents/CommonPatterns.md#cancellation/docs/)
     */
    @discardableResult
    func `catch`(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(Error) -> Void) -> Finalizer {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.return, flags: flags)
        return `catch`(on: dispatcher, policy: policy, body)
    }
    
    /**
     The provided closure executes when this promise rejects with the specific error passed in. A final `catch` is still required at the end of the chain.
     
     Rejecting a promise cascades: rejecting all subsequent promises (unless
     recover is invoked) thus you will typically place your catch at the end
     of a chain. Often utility promises will not have a catch, instead
     delegating the error handling to the caller.
     
     - Parameter only: The specific error to be caught and handled (e.g., `PMKError.emptySequence`).
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter flags: `DispatchWorkItemFlags` to be applied when dispatching.
     - Parameter body: The handler to execute if this promise is rejected with the provided error.
     - Note: Since this method handles only specific errors, supplying a `CatchPolicy` is unsupported.
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     */
    func `catch`<E: Swift.Error>(_ only: E, on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ body: @escaping() -> Void)
        -> CascadingFinalizer where E: Equatable
    {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.return, flags: flags)
        return `catch`(only, on: dispatcher, body)
    }
    
    /**
     The provided closure executes when this promise rejects with an error of the type passed in. A final `catch` is still required at the end of the chain.
     
     Rejecting a promise cascades: rejecting all subsequent promises (unless
     recover is invoked) thus you will typically place your catch at the end
     of a chain. Often utility promises will not have a catch, instead
     delegating the error handling to the caller.
     
     - Parameter only: The error type to be caught and handled (e.g., `PMKError`).
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter flags: `DispatchWorkItemFlags` to be applied when dispatching.
     - Parameter policy: A `CatchPolicy` that further constrains the errors this handler will see. E.g., if
     you are receiving `PMKError` errors, do you want to see even those that result from cancellation?
     - Parameter body: The handler to execute if this promise is rejected with the provided error type.
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     */
    func `catch`<E: Swift.Error>(_ only: E.Type, on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil,
        policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(E) -> Void) -> CascadingFinalizer
    {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.return, flags: flags)
        return `catch`(only, on: dispatcher, policy: policy, body)
    }
    
}


