// Since Guarantees have no error path, closures in the API are nonthrowing, which
// makes them different from the shared Promise/CancellablePromise API.

import Dispatch

public extension Guarantee {
    
    @discardableResult
    func then<U>(on: DispatchQueue? = .unspecified, flags: DispatchWorkItemFlags? = nil, _ body: @escaping(T) -> Guarantee<U>) -> Guarantee<U> {
        let dispatcher = on.convertToDispatcher(flags: flags)
        return then(on: dispatcher, body)
    }
    
    func map<U>(on: DispatchQueue? = .unspecified, flags: DispatchWorkItemFlags? = nil, _ body: @escaping(T) -> U) -> Guarantee<U> {
        let dispatcher = on.convertToDispatcher(flags: flags)
        return map(on: dispatcher, body)
    }
    
    @discardableResult
    func done(on: DispatchQueue? = .unspecified, flags: DispatchWorkItemFlags? = nil, _ body: @escaping(T) -> Void) -> Guarantee<Void> {
        let dispatcher = on.convertToDispatcher(flags: flags)
        return done(on: dispatcher, body)
    }
    
    func get(on: DispatchQueue? = .unspecified, flags: DispatchWorkItemFlags? = nil, _ body: @escaping (T) -> Void) -> Guarantee<T> {
        let dispatcher = on.convertToDispatcher(flags: flags)
        return get(on: dispatcher, body)
    }

    /// Set a default Dispatcher for the chain. Within the chain, this Dispatcher will remain the
    /// default until you change it, even if you dispatch individual closures to other Dispatchers.
    ///
    /// - Note: If you set a chain dispatcher within the body of a promise chain, you must
    ///   "confirm" the chain dispatcher when it gets to the tail to avoid a warning from
    ///   PromiseKit. To do this, just include `on: .chain` as an argument to the chain's
    ///   first `done`, `catch`, or `finally`.
    ///
    /// - Parameter on: The new default queue. Use `.default` to return to normal dispatching.
    /// - Parameter flags: `DispatchWorkItemFlags` to be applied when dispatching.
    
    func dispatch(on: DispatchQueue?, flags: DispatchWorkItemFlags? = nil) -> Guarantee<T> {
        let dispatcher = on.convertToDispatcher(flags: flags)
        return dispatch(on: dispatcher)
    }
}

public extension Guarantee where T: Sequence {
    
    func thenMap<U>(on: DispatchQueue? = .unspecified, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping(T.Iterator.Element) -> Guarantee<U>) -> Guarantee<[U]> {
        let dispatcher = on.convertToDispatcher(flags: flags)
        return thenMap(on: dispatcher, transform)
    }
    
}

