import Dispatch

/// A `PromiseKit` abstraction of a `DispatchQueue` that allows for a more
/// flexible variety of implementations. (For technical reasons,
/// `DispatchQueue` itself cannot be subclassed.)
///
/// `Dispatcher`s define a `dispatch` method that executes a supplied closure.
/// Execution may be synchronous or asynchronous, serial
/// or concurrent, and can occur on any thread.
///
/// All `DispatchQueue`s are also valid `Dispatcher`s.

public protocol Dispatcher {
    func dispatch(_ body: @escaping () -> Void)
}

/// A `Dispatcher` that bundles a `DispatchQueue` with
/// a `DispatchGroup`, a set of `DispatchWorkItemFlags`, and a
/// quality-of-service level. Closures dispatched through this
/// `Dispatcher` will be submitted to the underlying `DispatchQueue`
/// with the supplied components.

public struct DispatchQueueDispatcher: Dispatcher {
    
    let queue: DispatchQueue
    let group: DispatchGroup?
    let qos: DispatchQoS?
    var flags: DispatchWorkItemFlags?
    
    public init(queue: DispatchQueue, group: DispatchGroup? = nil, qos: DispatchQoS? = nil, flags: DispatchWorkItemFlags? = nil) {
        self.queue = queue
        self.group = group
        self.qos = qos
        self.flags = flags
    }
    
    mutating func replaceFlags(_ flags: DispatchWorkItemFlags) {
        self.flags = flags
    }

    public func dispatch(_ body: @escaping () -> Void) {
        queue.asyncD(group: group, qos: qos, flags: flags, execute: body)
    }
}

/// A `Dispatcher` class that executes all closures synchronously on
/// the current thread.
///
/// Useful for temporarily disabling asynchrony and
/// multithreading while debugging `PromiseKit` chains.
///
/// You can set `PromiseKit`'s default dispatching behavior to this mode
/// by calling conf.setDefaultDispatchers(body: nil, tail: nil) before
/// you create any promises.

public struct CurrentThreadDispatcher: Dispatcher {
    public func dispatch(_ body: () -> Void) {
        body()
    }
}

extension DispatchQueue: Dispatcher {
    public func dispatch(_ body: @escaping () -> Void) {
        async(execute: body)
    }
}

// Sentinel values used in the API. Since Dispatcher is a protocol and cannot
// have static members, all sentinel values must go through the wrapper path.
// These are converted as rapidly as possible into SentinelDispatcher structs.

public extension DispatchQueue {
    static let unspecified = DispatchQueue(label: "unspecified.promisekit.org") // Parameter not provided
    static let `default` = DispatchQueue(label: "default.promisekit.org")  // Explicit request for default behavior
    static let chain = DispatchQueue(label: "chain.promisekit.org")  // Execute on same Dispatcher as previous closure
}

public extension DispatchQueue {
    /// Converts a `DispatchQueue` with given dispatching parameters into a `Dispatcher`
    func asDispatcher(group: DispatchGroup? = nil, qos: DispatchQoS? = nil, flags: DispatchWorkItemFlags? = nil) -> Dispatcher {
        if group == nil && qos == nil && flags == nil {
            return self
        }
        return DispatchQueueDispatcher(queue: self, group: group, qos: qos, flags: flags)
    }
}

// Avoid having to hard-code any particular defaults for qos or flags
internal extension DispatchQueue {
    final func asyncD(group: DispatchGroup? = nil, qos: DispatchQoS? = nil, flags: DispatchWorkItemFlags? = nil, execute body: @escaping () -> Void) {
        switch (qos, flags) {
        case (nil, nil):
            async(group: group, execute: body)
        case (nil, let flags?):
            async(group: group, flags: flags, execute: body)
        case (let qos?, nil):
            async(group: group, qos: qos, execute: body)
        case (let qos?, let flags?):
            async(group: group, qos: qos, flags: flags, execute: body)
        }
    }
}

/// This function packages up a DispatchQueue and a DispatchWorkItemFlags? as a
/// Dispatcher for submission to the nonwrapper API.

extension DispatchQueue {
    func convertToDispatcher(flags: DispatchWorkItemFlags?) -> Dispatcher {
        switch self {
            case .unspecified: return SentinelDispatcher(type: .unspecified, flags: flags)
            case .default:     return SentinelDispatcher(type: .default, flags: flags)
            case .chain:       return SentinelDispatcher(type: .chain, flags: flags)
            default:
                if let flags = flags {
                    return self.asDispatcher(flags: flags)
                }
                return self
        }
    }
}

extension Optional where Wrapped: DispatchQueue {
    func convertToDispatcher(flags: DispatchWorkItemFlags?) -> Dispatcher {
        if let mapped = map({ $0.convertToDispatcher(flags: flags) }) { return mapped }
        if flags != nil {
            conf.logHandler(.extraneousFlagsSpecified)
        }
        return CurrentThreadDispatcher()
    }
}
