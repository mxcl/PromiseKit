import Dispatch

/// PromiseKit’s configurable parameters
public struct PMKConfiguration {
    /// Backward compatibility: default DispatchQueues that promise handlers dispatch to
    public var Q: (map: DispatchQueue?, return: DispatchQueue?) {
        get { return (map: D.map as? DispatchQueue, return: D.return as? DispatchQueue) }
        set { D = (map: newValue.map, return: newValue.return) }
    }

    /// The default Dispatchers that promise handlers dispatch to
    public var D: (map: Dispatcher?, return: Dispatcher?) = (map: DispatchQueue.main, return: DispatchQueue.main)

    /// The default catch-policy for all `catch` and `resolve`
    public var catchPolicy = CatchPolicy.allErrorsExceptCancellation
}

/// Modify this as soon as possible in your application’s lifetime
public var conf = PMKConfiguration()
