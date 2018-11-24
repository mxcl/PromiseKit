import Foundation

/**
    Specifies how certain PromiseKit events are logged.
    The default policy is .console. To set the logging
    policy, assign the desired policy in the PromiseKit
    configuration, e.g.:
    PromiseKit.conf.loggingPolicy = .none
 
    ````
    /// No Logging
    case none
 
    /// Output to console
    case console
 
    /// Log to the provided closure (closure must be thread safe)
    case custom((LogEvent) -> ())
    ````
*/
public enum LoggingPolicy {
    /// No Logging
    case none
    
    /// Output to console
    case console
    
    /// Log to the provided closure (closure must be thread safe)
    case custom((LogEvent) -> ())
}

/**
    The PromiseKit events which may be logged.
 
    ````
     /// A promise or guarantee has blocked the main thread
     case waitOnMainThread
 
     /// A promise has been deallocated without being fulfilled
     case pendingPromiseDeallocated
 
     /// An error which occurred while fulfilling a promise was swallowed
     case cauterized(Error)
    ````
*/
public enum LogEvent {
    /// A promise or guarantee has blocked the main thread
    case waitOnMainThread
    
    /// A promise has been deallocated without being fulfilled
    case pendingPromiseDeallocated
    
    /// An error which occurred while fulfilling a promise was swallowed
    case cauterized(Error)
}

/**
    Block the current thread until all pending events on the
    PromiseKit logging queue have completed. Intended only for use
    during testing.
*/
public func waitOnLogging() {
    conf.loggingQueue.sync(){}
}

internal func log(_ event: PromiseKit.LogEvent) {
    conf.loggingQueue.async {
        conf.activeLoggingClosure(event)
    }
}
