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
}
