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
    
    /// DispatchWorkItem flags specified for non-DispatchQueue Dispatcher
    case extraneousFlagsSpecified

    /// Entered the tail of a chain with a chain dispatcher and without confirming the intent to use
    /// the chain dispatcher within the tail.
    case failedToConfirmChainDispatcher
    
    /// Default dispatchers were modified after promises were created
    case defaultDispatchersReset
    
    /// Used `on: .chain` when no chain dispatcher is set
    case chainWithoutChainDispatcher

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
            case .extraneousFlagsSpecified:
                message = " warning: DispatchWorkItemFlags flags specified, but default Dispatcher is not a DispatchQueue (ignored)"
            case .failedToConfirmChainDispatcher:
                return "Entered the tail of a promise chain with a chain-specific dispatcher (set by `dispatch(on:)`) without confirming the dispatcher. To confirm that it's the behavior you expect, and silence this warning, include an `on: .chain` parameter in the first call to `done`, `catch`, or `finally`."
            case .defaultDispatchersReset:
                return "Default dispatchers should not be modified after you have created promises. This restriction will be enforced in a future version of PromiseKit. Use `dispatch(on:)` to set local defaults."
            case .chainWithoutChainDispatcher:
                return "`on: .chain` was specified when no chain dispatcher is defined; ignoring"
        }
        return "PromiseKit:\(message)"
    }
}
