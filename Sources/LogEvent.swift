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
    
    public func asString() -> String {
        var message: String
        switch self {
            case .waitOnMainThread:
                message = " warning: `wait()` called on main thread!"
            case .pendingPromiseDeallocated:
                message = " warning: pending promise deallocated"
            case .pendingGuaranteeDeallocated:
                message = " warning: pending guarantee deallocated"
            case .cauterized(let error):
                message = "cauterized-error: \(error)"
            case .nilDispatchQueueWithFlags:
                message = " warning: nil DispatchQueue specified, but DispatchWorkItemFlags were also supplied (ignored)"
            case .extraneousFlagsSpecified:
                message = " warning: DispatchWorkItemFlags flags specified, but default Dispatcher is not a DispatchQueue (ignored)"
        }
        return "PromiseKit:\(message)"
    }
}
