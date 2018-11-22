import Dispatch

/// PromiseKit’s configurable parameters
public struct PMKConfiguration {
    /// The default queues that promises handlers dispatch to
    public var Q: (map: DispatchQueue?, return: DispatchQueue?) = (map: DispatchQueue.main, return: DispatchQueue.main)

    /// The default catch-policy for all `catch` and `resolve`
    public var catchPolicy = CatchPolicy.allErrorsExceptCancellation
    
    /// Defines how events (defined by PromiseKit.LogEvent) are logged. default: .console
    public var loggingPolicy: LoggingPolicy = PromiseKit.LoggingPolicy.console {
        willSet (newValue) {
            loggingQueue.sync() {
                switch newValue {
                case .none:
                    activeLoggingClosure = { event in }
                case .console:
                    activeLoggingClosure = PMKConfiguration.logConsoleClosure
                case .custom (let closure):
                    activeLoggingClosure = closure
                }
            }
        }
    }

    // The closure currently being used to log PromiseKit events
    internal var activeLoggingClosure: (LogEvent) -> () = logConsoleClosure
    
    // A closure which logs PromiseKit.LogEvent to console
    internal static let logConsoleClosure: (LogEvent) -> () = { event in
        switch event {
        case .waitOnMainThread:
            print ("PromiseKit: warning: `wait()` called on main thread!")
        case .pendingPromiseDeallocated:
            print ("PromiseKit: warning: pending promise deallocated")
        case .cauterized (let error):
            print("PromiseKit:cauterized-error: \(error)")
        }
    }
    
    // A queue protecting access to the activeLoggingClosure
    internal let loggingQueue = DispatchQueue(label: "PromiseKitLogging")
    
}

/// Modify this as soon as possible in your application’s lifetime
public var conf = PMKConfiguration()
