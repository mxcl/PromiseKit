import Dispatch

/// PromiseKit’s configurable parameters
public struct PMKConfiguration {
    /// The default queues that promises handlers dispatch to
    public var Q: (map: DispatchQueue?, return: DispatchQueue?) = (map: DispatchQueue.main, return: DispatchQueue.main)

    /// The default catch-policy for all `catch` and `resolve`
    public var catchPolicy = CatchPolicy.allErrorsExceptCancellation
}

/// Modify this as soon as possible in your application’s lifetime
public var conf = PMKConfiguration()
