import Dispatch

/// PromiseKit’s configurable parameters
public struct PMKConfiguration {
    /// The default queues that promises handlers dispatch to
    public var Q: (map: DispatchQueue?, return: DispatchQueue?) = (map: DispatchQueue.main, return: DispatchQueue.main)

    /// The default catch-policy for all `catch` and `resolve`
    public var catchPolicy = CatchPolicy.allErrorsExceptCancellation
    
    /// The closure used to log PromiseKit events.
    /// Not thread safe; change before processing any promises.
    /// Default: Log to console.
    internal var loggingClosure: (LogEvent) -> () = { event in
        switch event {
        case .waitOnMainThread:
            print ("PromiseKit: warning: `wait()` called on main thread!")
        case .pendingPromiseDeallocated:
            print ("PromiseKit: warning: pending promise deallocated")
        case .cauterized (let error):
            print("PromiseKit:cauterized-error: \(error)")
        case .misc(let errorMessage):
            print (errorMessage)
        }
    }
}

/// Modify this as soon as possible in your application’s lifetime
public var conf = PMKConfiguration()
