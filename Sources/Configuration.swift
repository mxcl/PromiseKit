import Dispatch

/**
 PromiseKit’s configurable parameters.

 Do not change these after any Promise machinery executes as the configuration object is not thread-safe.

 We would like it to be, but sadly `Swift` does not expose `dispatch_once` et al. which is what we used to use in order to make the configuration immutable once first used.
*/
public struct PMKConfiguration {
    /// Backward compatibility: the default Dispatcher to which handlers dispatch, represented as DispatchQueues.
    public var Q: (map: DispatchQueue?, return: DispatchQueue?) {
        get {
            let convertedMap = D.map is CurrentThreadDispatcher ? nil : D.map as? DispatchQueue
            let convertedReturn = D.return is CurrentThreadDispatcher ? nil : D.return as? DispatchQueue
            return (map: convertedMap, return: convertedReturn)
        }
        set { D = (map: newValue.map ?? CurrentThreadDispatcher(), return: newValue.return ?? CurrentThreadDispatcher()) }
    }

    /// The default Dispatchers to which promise handlers dispatch
    public var D: (map: Dispatcher, return: Dispatcher) = (map: DispatchQueue.main, return: DispatchQueue.main)

    /// The default catch-policy for all `catch` and `resolve`
    public var catchPolicy = CatchPolicy.allErrorsExceptCancellation

    /// The closure used to log PromiseKit events.
    /// Not thread safe; change before processing any promises.
    /// - Note: The default handler calls `print()`
    public var logHandler: (LogEvent) -> Void = { event in
        switch event {
        case .waitOnMainThread:
            print("PromiseKit: warning: `wait()` called on main thread!")
        case .pendingPromiseDeallocated:
            print("PromiseKit: warning: pending promise deallocated")
        case .pendingGuaranteeDeallocated:
            print("PromiseKit: warning: pending guarantee deallocated")
        case .cauterized (let error):
            print("PromiseKit:cauterized-error: \(error)")
        }
    }
}

/// Modify this as soon as possible in your application’s lifetime
public var conf = PMKConfiguration()
