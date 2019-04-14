import Dispatch

/// Simple wrapper that packages dot arguments as a Dispatcher.

struct SentinelDispatcher: Dispatcher {
    
    enum SentinelType {
        case unspecified  // Parameter not provided
        case `default`    // Explicit request for global default
        case chain        // Explicit request to use the chain dispatcher
    }
    
    let type: SentinelType
    let flags: DispatchWorkItemFlags?
    
    func dispatch(_ body: @escaping () -> Void) {
        fatalError("Attempted to dispatch a closure on a SentinelDispatcher")
    }
    
    func applyFlags(to dispatcher: Dispatcher) -> Dispatcher {
        guard let flags = flags else { return dispatcher }
        // See if we can incorporate the provided flags into whatever dispatcher we ended up with
        if var dqd = dispatcher as? DispatchQueueDispatcher {
            dqd.replaceFlags(flags)
            return dqd
        } else if let queue = dispatcher as? DispatchQueue {
            return queue.asDispatcher(flags: flags)
        } else {
            conf.logHandler(.extraneousFlagsSpecified)
            return dispatcher
        }
    }
}
