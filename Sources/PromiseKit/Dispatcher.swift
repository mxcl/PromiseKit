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
    let flags: DispatchWorkItemFlags?
    
    public init(queue: DispatchQueue, group: DispatchGroup? = nil, qos: DispatchQoS? = nil, flags: DispatchWorkItemFlags? = nil) {
        self.queue = queue
        self.group = group
        self.qos = qos
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
/// by setting `conf.Q.map` and/or `conf.Q.return` to `nil`. (This is the
/// same as assigning an instance of `CurrentThreadDispatcher` to these
/// variables.)

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

// Used as default parameter for backward compatibility since clients may explicitly
// specify "nil" to turn off dispatching. We need to distinguish three cases: explicit
// queue, explicit nil, and no value specified. Dispatchers from conf.D cannot directly
// be used as default parameter values because they are not necessarily DispatchQueues.

public extension DispatchQueue {
    static var pmkDefault = DispatchQueue(label: "org.promisekit.sentinel")
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

// This hairball disambiguates all the various combinations of explicit arguments, default
// arguments, and configured defaults. In particular, a method that is given explicit work item
// flags but no DispatchQueue should still work (that is, the dispatcher should use those flags)
// as long as the configured default is actually some kind of DispatchQueue.

internal func selectDispatcher(given: DispatchQueue?, configured: Dispatcher, flags: DispatchWorkItemFlags?) -> Dispatcher {
    guard let given = given else {
        if flags != nil {
            conf.logHandler(.nilDispatchQueueWithFlags)
        }
        return CurrentThreadDispatcher()
    }
    if given !== DispatchQueue.pmkDefault {
        return given.asDispatcher(flags: flags)
    } else if let flags = flags, let configured = configured as? DispatchQueue {
        return configured.asDispatcher(flags: flags)
    } else if flags != nil {
        conf.logHandler(.extraneousFlagsSpecified)
    }
    return configured
}
