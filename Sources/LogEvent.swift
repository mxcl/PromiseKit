/**
    The PromiseKit events which may be logged.
 
    ````
    /// A promise or guarantee has blocked the main thread
    case waitOnMainThread
 
    /// A promise has been deallocated without being resolved
    case pendingPromiseDeallocated
 
    /// An error which occurred while fulfilling a promise was swallowed
    case cauterized(Error)
 
    /// Errors which give a string error message
    case misc (String)
    ````
*/
public enum LogEvent {
    /// A promise or guarantee has blocked the main thread
    case waitOnMainThread
    
    /// A promise has been deallocated without being resolved
    case pendingPromiseDeallocated
    
    /// A guarantee has been deallocated without being resolved
    case pendingGuaranteeDeallocated
    
    /// An error which occurred while resolving a promise was swallowed
    case cauterized(Error)
    
    /// Odd arguments to DispatchQueue-compatibility layer
    case nilDispatchQueueWithFlags
    
    /// DispatchWorkItem flags specified for non-DispatchQueue Dispatcher
    case extraneousFlagsSpecified
}

extension LogEvent: CustomStringConvertible {
    public var description: String {
        switch self {
        case .waitOnMainThread:
            return "warning: `wait()` called on main thread!"
        case .pendingPromiseDeallocated:
            return "warning: pending promise deallocated"
        case .pendingGuaranteeDeallocated:
            return "warning: pending guarantee deallocated"
        case .cauterized(let error):
            return "cauterized-error: \(error)"
        case .nilDispatchQueueWithFlags:
            return "warning: nil DispatchQueue specified, but DispatchWorkItemFlags were also supplied (ignored)"
        case .extraneousFlagsSpecified:
            return "warning: DispatchWorkItemFlags flags specified, but default Dispatcher is not a DispatchQueue (ignored)"
        }
    }
}
