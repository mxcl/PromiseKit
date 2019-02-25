import Dispatch

public protocol Dispatcher {
    func dispatch(_ body: @escaping () -> Void)
}

public class DispatchQueueDispatcher: Dispatcher {
    
    let queue: DispatchQueue
    let flags: DispatchWorkItemFlags
    
    init(queue: DispatchQueue, flags: DispatchWorkItemFlags) {
        self.queue = queue
        self.flags = flags
    }

    public func dispatch(_ body: @escaping () -> Void) {
        queue.async(flags: flags, execute: body)
    }

}

public struct CurrentThreadDispatcher: Dispatcher {
    public func dispatch(_ body: @escaping () -> Void) {
        body()
    }
}

extension DispatchQueue: Dispatcher {
    /// Explicit declaration required; actual function signature is not identical to protocol
    public func dispatch(_ body: @escaping () -> Void) {
        async(execute: body)
    }
}

/// Used as default parameter for backward compatibility since clients may explicitly
/// specify "nil" to turn off dispatching. We need to distinguish three cases: explicit
/// queue, explicit nil, and no value specified. Dispatchers from conf.D cannot directly
/// be used as default parameter values because they are not necessarily DispatchQueues.

public extension DispatchQueue {
    static var pmkDefault = DispatchQueue(label: "org.promisekit.sentinel")
}

public extension DispatchQueue {
    func asDispatcher(withFlags flags: DispatchWorkItemFlags? = nil) -> Dispatcher {
        if let flags = flags {
            return DispatchQueueDispatcher(queue: self, flags: flags)
        }
        return self
    }
}

/// This hairball disambiguates all the various combinations of explicit arguments, default
/// arguments, and configured defaults. In particular, a method that is given explicit work item
/// flags but no DispatchQueue should still work (that is, the dispatcher should use those flags)
/// as long as the configured default is actually some kind of DispatchQueue.
///
/// TODO: should conf.D = nil turn off dispatching even if explicit dispatch arguments are given?
/// TODO: Move log prints into LogError enum if they are kept

fileprivate func selectDispatcher(given: DispatchQueue?, configured: Dispatcher, flags: DispatchWorkItemFlags?) -> Dispatcher {
    guard let given = given else {
        if flags != nil {
            print("PromiseKit: warning: nil DispatchQueue specified, but DispatchWorkItemFlags were also supplied (ignored)")
        }
        return CurrentThreadDispatcher()
    }
    if given !== DispatchQueue.pmkDefault {
        return given.asDispatcher(withFlags: flags)
    } else if let flags = flags, let configured = configured as? DispatchQueue {
        return configured.asDispatcher(withFlags: flags)
    } else if flags != nil {
        print("PromiseKit: warning: DispatchWorkItemFlags flags specified, but default dispatcher is not a DispatchQueue (ignored)")
    }
    return configured
}

/// Backward compatibility for DispatchQueues in public API

public extension Guarantee {
    
    @discardableResult
    func done(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ body: @escaping(T) -> Void) -> Guarantee<Void> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.return, flags: flags)
        return done(on: dispatcher, body)
    }

    func get(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ body: @escaping (T) -> Void) -> Guarantee<T> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.return, flags: flags)
        return get(on: dispatcher, body)
    }
    
    func map<U>(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ body: @escaping(T) -> U) -> Guarantee<U> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return map(on: dispatcher, body)
    }

    @discardableResult
    func then<U>(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ body: @escaping(T) -> Guarantee<U>) -> Guarantee<U> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return then(on: dispatcher, body)
    }

}

public extension Guarantee where T: Sequence {
    
    func thenMap<U>(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping(T.Iterator.Element) -> Guarantee<U>) -> Guarantee<[U]> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return thenMap(on: dispatcher, transform)
    }
    
}

public extension Thenable {
    
    /**
     The provided closure executes when this promise resolves.
     
     This allows chaining promises. The promise returned by the provided closure is resolved before the promise returned by this closure resolves.
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The closure that executes when this promise fulfills. It must return a promise.
     - Returns: A new promise that resolves when the promise returned from the provided closure resolves. For example:
     
         firstly {
            URLSession.shared.dataTask(.promise, with: url1)
         }.then { response in
            transform(data: response.data)
         }.done { transformation in
            //…
         }
     */
    func then<U: Thenable>(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ body: @escaping(T) throws -> U) -> Promise<U.T> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return then(on: dispatcher, body)
    }
    
    /**
     The provided closure is executed when this promise is resolved.
     
     This is like `then` but it requires the closure to return a non-promise.
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter transform: The closure that is executed when this Promise is fulfilled. It must return a non-promise.
     - Returns: A new promise that is resolved with the value returned from the provided closure. For example:
     
         firstly {
            URLSession.shared.dataTask(.promise, with: url1)
         }.map { response in
            response.data.length
         }.done { length in
            //…
         }
     */
    func map<U>(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping(T) throws -> U) -> Promise<U> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return map(on: dispatcher, transform)
    }

    /**
     The provided closure is executed when this promise is resolved.
     
     In your closure return an `Optional`, if you return `nil` the resulting promise is rejected with `PMKError.compactMap`, otherwise the promise is fulfilled with the unwrapped value.
     
         firstly {
            URLSession.shared.dataTask(.promise, with: url)
         }.compactMap {
            try JSONSerialization.jsonObject(with: $0.data) as? [String: String]
         }.done { dictionary in
            //…
         }.catch {
            // either `PMKError.compactMap` or a `JSONError`
         }
     */
    func compactMap<U>(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping(T) throws -> U?) -> Promise<U> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return compactMap(on: dispatcher, transform)
    }
    
    /**
     The provided closure is executed when this promise is resolved.
     
     Equivalent to `map { x -> Void in`, but since we force the `Void` return Swift
     is happier and gives you less hassle about your closure’s qualification.
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The closure that is executed when this Promise is fulfilled.
     - Returns: A new promise fulfilled as `Void`.
     
         firstly {
            URLSession.shared.dataTask(.promise, with: url)
         }.done { response in
            print(response.data)
         }
     */
    func done(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ body: @escaping(T) throws -> Void) -> Promise<Void> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.return, flags: flags)
        return done(on: dispatcher, body)
    }
    
    /**
     The provided closure is executed when this promise is resolved.
     
     This is like `done` but it returns the same value that the handler is fed.
     `get` immutably accesses the fulfilled value; the returned Promise maintains that value.
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The closure that is executed when this Promise is fulfilled.
     - Returns: A new promise that is resolved with the value that the handler is fed. For example:
     
         firstly {
            .value(1)
         }.get { foo in
            print(foo, " is 1")
         }.done { foo in
            print(foo, " is 1")
         }.done { foo in
            print(foo, " is Void")
         }
     */
    func get(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ body: @escaping (T) throws -> Void) -> Promise<T> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.return, flags: flags)
        return get(on: dispatcher, body)
    }
    
    /**
     The provided closure is executed with promise result.
     
     This is like `get` but provides the Result<T> of the Promise so you can inspect the value of the chain at this point without causing any side effects.
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The closure that is executed with Result of Promise.
     - Returns: A new promise that is resolved with the result that the handler is fed. For example:
     
     promise.tap{ print($0) }.then{ /*…*/ }
     */
    func tap(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ body: @escaping(Result<T, Error>) -> Void) -> Promise<T> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return tap(on: dispatcher, body)
    }

}

public extension Thenable where T: Sequence {
    /**
     `Promise<[T]>` => `T` -> `U` => `Promise<[U]>`
     
         firstly {
            .value([1,2,3])
         }.mapValues { integer in
            integer * 2
         }.done {
            // $0 => [2,4,6]
         }
     */
    func mapValues<U>(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping(T.Iterator.Element) throws -> U) -> Promise<[U]> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return mapValues(on: dispatcher, transform)
    }
    
    /**
     `Promise<[T]>` => `T` -> `[U]` => `Promise<[U]>`
     
         firstly {
            .value([1,2,3])
         }.flatMapValues { integer in
            [integer, integer]
         }.done {
            // $0 => [1,1,2,2,3,3]
         }
     */
    func flatMapValues<U: Sequence>(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping(T.Iterator.Element) throws -> U) -> Promise<[U.Iterator.Element]> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return flatMapValues(on: dispatcher, transform)
    }
    
    /**
     `Promise<[T]>` => `T` -> `U?` => `Promise<[U]>`
     
         firstly {
            .value(["1","2","a","3"])
         }.compactMapValues {
            Int($0)
         }.done {
            // $0 => [1,2,3]
         }
     */
    func compactMapValues<U>(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping(T.Iterator.Element) throws -> U?) -> Promise<[U]> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return compactMapValues(on: dispatcher, transform)
    }
    
    /**
     `Promise<[T]>` => `T` -> `Promise<U>` => `Promise<[U]>`
     
         firstly {
            .value([1,2,3])
         }.thenMap { integer in
            .value(integer * 2)
         }.done {
            // $0 => [2,4,6]
         }
     */
    func thenMap<U: Thenable>(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping(T.Iterator.Element) throws -> U) -> Promise<[U.T]> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return thenMap(on: dispatcher, transform)
    }

    /**
     `Promise<[T]>` => `T` -> `Promise<[U]>` => `Promise<[U]>`
     
         firstly {
            .value([1,2,3])
         }.thenFlatMap { integer in
            .value([integer, integer])
         }.done {
            // $0 => [1,1,2,2,3,3]
         }
     */
    func thenFlatMap<U: Thenable>(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping(T.Iterator.Element) throws -> U) -> Promise<[U.T.Iterator.Element]> where U.T: Sequence {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return thenFlatMap(on: dispatcher, transform)
    }
    
    /**
     `Promise<[T]>` => `T` -> Bool => `Promise<[U]>`
     
         firstly {
            .value([1,2,3])
         }.filterValues {
            $0 > 1
         }.done {
            // $0 => [2,3]
         }
     */
    func filterValues(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ isIncluded: @escaping (T.Iterator.Element) -> Bool) -> Promise<[T.Iterator.Element]> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return filterValues(on: dispatcher, isIncluded)
    }
}

public extension Thenable where T: Collection {
    func firstValue(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, where test: @escaping (T.Iterator.Element) -> Bool) -> Promise<T.Iterator.Element> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return firstValue(on: dispatcher, where: test)
    }
}

public extension Thenable where T: Sequence, T.Iterator.Element: Comparable {
    /// - Returns: a promise fulfilled with the sorted values of this `Sequence`.
    func sortedValues(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil) -> Promise<[T.Iterator.Element]> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return sortedValues(on: dispatcher)
    }
}

public extension CatchMixin {
    /**
     The provided closure executes when this promise rejects.
     
     Rejecting a promise cascades: rejecting all subsequent promises (unless
     recover is invoked) thus you will typically place your catch at the end
     of a chain. Often utility promises will not have a catch, instead
     delegating the error handling to the caller.
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter policy: The default policy does not execute your handler for cancellation errors.
     - Parameter execute: The handler to execute if this promise is rejected.
     - Returns: A promise finalizer.
     - SeeAlso: [Cancellation](http://https://github.com/mxcl/PromiseKit/blob/master/Documentation/CommonPatterns.md#cancellation/docs/)
     */
    @discardableResult
    func `catch`(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(Error) -> Void) -> PMKFinalizer {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.return, flags: flags)
        return `catch`(on: dispatcher, policy: policy, body)
    }

    /**
     The provided closure executes when this promise rejects.
     
     Unlike `catch`, `recover` continues the chain.
     Use `recover` in circumstances where recovering the chain from certain errors is a possibility. For example:
     
         firstly {
            CLLocationManager.requestLocation()
         }.recover { error in
            guard error == CLError.unknownLocation else { throw error }
            return .value(CLLocation.chicago)
         }
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The handler to execute if this promise is rejected.
     - SeeAlso: [Cancellation](http://https://github.com/mxcl/PromiseKit/blob/master/Documentation/CommonPatterns.md#cancellation/docs/)
     */
    func recover<U: Thenable>(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(Error) throws -> U) -> Promise<T> where U.T == T {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return recover(on: dispatcher, policy: policy, body)
    }
    
    /**
     The provided closure executes when this promise rejects.
     This variant of `recover` requires the handler to return a Guarantee, thus it returns a Guarantee itself and your closure cannot `throw`.
     - Note it is logically impossible for this to take a `catchPolicy`, thus `allErrors` are handled.
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The handler to execute if this promise is rejected.
     - SeeAlso: [Cancellation](http://https://github.com/mxcl/PromiseKit/blob/master/Documentation/CommonPatterns.md#cancellation/docs/)
     */
    @discardableResult
    func recover(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ body: @escaping(Error) -> Guarantee<T>) -> Guarantee<T> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return recover(on: dispatcher, body)
    }

    /**
     The provided closure executes when this promise resolves, whether it rejects or not.
     
         firstly {
            UIApplication.shared.networkActivityIndicatorVisible = true
         }.done {
            //…
         }.ensure {
            UIApplication.shared.networkActivityIndicatorVisible = false
         }.catch {
            //…
         }
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The closure that executes when this promise resolves.
     - Returns: A new promise, resolved with this promise’s resolution.
     */
    func ensure(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ body: @escaping () -> Void) -> Promise<T> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.return, flags: flags)
        return ensure(on: dispatcher, body)
    }

    /**
     The provided closure executes when this promise resolves, whether it rejects or not.
     The chain waits on the returned `Guarantee<Void>`.
     
         firstly {
            setup()
         }.done {
            //…
         }.ensureThen {
            teardown()  // -> Guarante<Void>
         }.catch {
            //…
         }
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The closure that executes when this promise resolves.
     - Returns: A new promise, resolved with this promise’s resolution.
     */
    func ensureThen(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ body: @escaping () -> Guarantee<Void>) -> Promise<T> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.return, flags: flags)
        return ensureThen(on: dispatcher, body)
    }
}

public extension PMKFinalizer {
    /// `finally` is the same as `ensure`, but it is not chainable
    func finally(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ body: @escaping () -> Void) {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.return, flags: flags)
        return finally(on: dispatcher, body)
    }
}

public extension CatchMixin where T == Void {
    
    /**
     The provided closure executes when this promise rejects.
     
     This variant of `recover` is specialized for `Void` promises and de-errors your chain returning a `Guarantee`, thus you cannot `throw` and you must handle all errors including cancellation.
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The handler to execute if this promise is rejected.
     - SeeAlso: [Cancellation](http://https://github.com/mxcl/PromiseKit/blob/master/Documentation/CommonPatterns.md#cancellation/docs/)
     */
    @discardableResult
    func recover(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ body: @escaping(Error) -> Void) -> Guarantee<Void> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return recover(on: dispatcher, body)
    }

    /**
     The provided closure executes when this promise rejects.
     
     This variant of `recover` ensures that no error is thrown from the handler and allows specifying a catch policy.
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The handler to execute if this promise is rejected.
     - SeeAlso: [Cancellation](http://https://github.com/mxcl/PromiseKit/blob/master/Documentation/CommonPatterns.md#cancellation/docs/)
     */
    func recover(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(Error) throws -> Void) -> Promise<Void> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return recover(on: dispatcher, policy: policy, body)
    }
}

//////////////////////////////////////////////////////////// Cancellation

public extension CancellableThenable {
    /**
     The provided closure executes when this cancellable promise resolves.
     
     This allows chaining promises. The cancellable promise returned by the provided closure is resolved before the cancellable promise returned by this closure resolves.
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The closure that executes when this cancellable promise fulfills. It must return a cancellable promise.
     - Returns: A new cancellable promise that resolves when the promise returned from the provided closure resolves. For example:

           let context = firstly {
               URLSession.shared.cancellableDataTask(.promise, with: url1)
           }.then { response in
               transform(data: response.data) // returns a CancellablePromise
           }.done { transformation in
               //…
           }.cancelContext
     
           //…
     
           context.cancel()
     */
    func then<V: CancellableThenable>(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, _ body: @escaping (U.T) throws -> V) -> CancellablePromise<V.U.T> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return then(on: dispatcher, body)
    }

    /**
     The provided closure executes when this cancellable promise resolves.
     
     This allows chaining promises. The promise returned by the provided closure is resolved before the cancellable promise returned by this closure resolves.
     
     - Parameter on: The dispatcher that executes the provided closure.
     - Parameter body: The closure that executes when this cancellable promise fulfills. It must return a promise (not a cancellable promise).
     - Returns: A new cancellable promise that resolves when the promise returned from the provided closure resolves. For example:

           let context = firstly {
               URLSession.shared.cancellableDataTask(.promise, with: url1)
           }.cancellableThen { response in
               transform(data: response.data) // returns a Promise
           }.done { transformation in
               //…
           }.cancelContext
     
           //…
     
           context.cancel()
     */
    func cancellableThen<V: Thenable>(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, _ body: @escaping (U.T) throws -> V) -> CancellablePromise<V.T> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return cancellableThen(on: dispatcher, body)
    }
    
    /**
     The provided closure is executed when this cancellable promise is resolved.
     
     This is like `then` but it requires the closure to return a non-promise and non-cancellable-promise.
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter transform: The closure that is executed when this CancellablePromise is fulfilled. It must return a non-promise and non-cancellable-promise.
     - Returns: A new cancellable promise that is resolved with the value returned from the provided closure. For example:

           let context = firstly {
               URLSession.shared.cancellableDataTask(.promise, with: url1)
           }.map { response in
               response.data.length
           }.done { length in
               //…
           }.cancelContext

           //…
     
           context.cancel()
     */
    func map<V>(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping (U.T) throws -> V) -> CancellablePromise<V> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return map(on: dispatcher, transform)
    }

    /**
      The provided closure is executed when this cancellable promise is resolved.

      In your closure return an `Optional`, if you return `nil` the resulting cancellable promise is rejected with `PMKError.compactMap`, otherwise the cancellable promise is fulfilled with the unwrapped value.

           let context = firstly {
               URLSession.shared.cancellableDataTask(.promise, with: url)
           }.compactMap {
               try JSONSerialization.jsonObject(with: $0.data) as? [String: String]
           }.done { dictionary in
               //…
           }.catch {
               // either `PMKError.compactMap` or a `JSONError`
           }.cancelContext

           //…
     
           context.cancel()
     */
    func compactMap<V>(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping (U.T) throws -> V?) -> CancellablePromise<V> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return compactMap(on: dispatcher, transform)
    }

    /**
     The provided closure is executed when this cancellable promise is resolved.
     
     Equivalent to `map { x -> Void in`, but since we force the `Void` return Swift
     is happier and gives you less hassle about your closure’s qualification.
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The closure that is executed when this promise is fulfilled.
     - Returns: A new cancellable promise fulfilled as `Void`.
     
           let context = firstly {
               URLSession.shared.cancellableDataTask(.promise, with: url)
           }.done { response in
               print(response.data)
           }.cancelContext

           //…
     
           context.cancel()
     */
    func done(on: DispatchQueue? = conf.Q.return, flags: DispatchWorkItemFlags? = nil, _ body: @escaping (U.T) throws -> Void) -> CancellablePromise<Void> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.return, flags: flags)
        return done(on: dispatcher, body)
    }

    /**
     The provided closure is executed when this cancellable promise is resolved.
     
     This is like `done` but it returns the same value that the handler is fed.
     `get` immutably accesses the fulfilled value; the returned CancellablePromise maintains that value.
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The closure that is executed when this CancellablePromise is fulfilled.
     - Returns: A new cancellable promise that is resolved with the value that the handler is fed. For example:
     
           let context = firstly {
               cancellable(Promise.value(1))
           }.get { foo in
               print(foo, " is 1")
           }.done { foo in
               print(foo, " is 1")
           }.done { foo in
               print(foo, " is Void")
           }.cancelContext

           //…
     
           context.cancel()
     */
    func get(on: DispatchQueue? = conf.Q.return, flags: DispatchWorkItemFlags? = nil, _ body: @escaping (U.T) throws -> Void) -> CancellablePromise<U.T> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.return, flags: flags)
        return get(on: dispatcher, body)
    }

    /**
     The provided closure is executed with cancellable promise result.

     This is like `get` but provides the Result<U.T> of the CancellablePromise so you can inspect the value of the chain at this point without causing any side effects.

     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The closure that is executed with Result of CancellablePromise.
     - Returns: A new cancellable promise that is resolved with the result that the handler is fed. For example:

     promise.tap{ print($0) }.then{ /*…*/ }
     */
    func tap(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, _ body: @escaping(Result<U.T, Error>) -> Void) -> CancellablePromise<U.T> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return tap(on: dispatcher, body)
    }
}

public extension CancellableThenable where U.T: Sequence {
    /**
     `CancellablePromise<[U.T]>` => `U.T` -> `V` => `CancellablePromise<[V]>`

         firstly {
             cancellable(Promise.value([1,2,3]))
         }.mapValues { integer in
             integer * 2
         }.done {
             // $0 => [2,4,6]
         }
     */
    func mapValues<V>(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping(U.T.Iterator.Element) throws -> V) -> CancellablePromise<[V]> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return mapValues(on: dispatcher, transform)
    }

    /**
     `CancellablePromise<[U.T]>` => `U.T` -> `[V]` => `CancellablePromise<[V]>`

         firstly {
             cancellable(Promise.value([1,2,3]))
         }.flatMapValues { integer in
             [integer, integer]
         }.done {
             // $0 => [1,1,2,2,3,3]
         }
     */
    func flatMapValues<V: Sequence>(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping(U.T.Iterator.Element) throws -> V) -> CancellablePromise<[V.Iterator.Element]> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return flatMapValues(on: dispatcher, transform)
    }

    /**
     `CancellablePromise<[U.T]>` => `U.T` -> `V?` => `CancellablePromise<[V]>`

         firstly {
             cancellable(Promise.value(["1","2","a","3"]))
         }.compactMapValues {
             Int($0)
         }.done {
             // $0 => [1,2,3]
         }
     */
    func compactMapValues<V>(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping(U.T.Iterator.Element) throws -> V?) -> CancellablePromise<[V]> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return compactMapValues(on: dispatcher, transform)
    }

    /**
     `CancellablePromise<[U.T]>` => `U.T` -> `CancellablePromise<V>` => `CancellablePromise<[V]>`

         firstly {
             cancellable(Promise.value([1,2,3]))
         }.thenMap { integer in
             cancellable(Promise.value(integer * 2))
         }.done {
             // $0 => [2,4,6]
         }
     */
    func thenMap<V: CancellableThenable>(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping(U.T.Iterator.Element) throws -> V) -> CancellablePromise<[V.U.T]> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return thenMap(on: dispatcher, transform)
    }

    /**
     `CancellablePromise<[U.T]>` => `U.T` -> `Promise<V>` => `CancellablePromise<[V]>`

         firstly {
             cancellable(Promise.value([1,2,3]))
         }.thenMap { integer in
             .value(integer * 2)
         }.done {
             // $0 => [2,4,6]
         }
     */
    func cancellableThenMap<V: Thenable>(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping(U.T.Iterator.Element) throws -> V) -> CancellablePromise<[V.T]> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return cancellableThenMap(on: dispatcher, transform)
    }

    /**
     `CancellablePromise<[T]>` => `T` -> `CancellablePromise<[U]>` => `CancellablePromise<[U]>`

         firstly {
             cancellable(Promise.value([1,2,3]))
         }.thenFlatMap { integer in
             cancellable(Promise.value([integer, integer]))
         }.done {
             // $0 => [1,1,2,2,3,3]
         }
     */
    func thenFlatMap<V: CancellableThenable>(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping(U.T.Iterator.Element) throws -> V) -> CancellablePromise<[V.U.T.Iterator.Element]> where V.U.T: Sequence {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return thenFlatMap(on: dispatcher, transform)
    }

    /**
     `CancellablePromise<[T]>` => `T` -> `Promise<[U]>` => `CancellablePromise<[U]>`

         firstly {
             cancellable(Promise.value([1,2,3]))
         }.thenFlatMap { integer in
             .value([integer, integer])
         }.done {
             // $0 => [1,1,2,2,3,3]
         }
     */
    func cancellableThenFlatMap<V: Thenable>(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping(U.T.Iterator.Element) throws -> V) -> CancellablePromise<[V.T.Iterator.Element]> where V.T: Sequence {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return cancellableThenFlatMap(on: dispatcher, transform)
    }

    /**
     `CancellablePromise<[T]>` => `T` -> Bool => `CancellablePromise<[U]>`

         firstly {
             cancellable(Promise.value([1,2,3]))
         }.filterValues {
             $0 > 1
         }.done {
             // $0 => [2,3]
         }
     */
    func filterValues(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, _ isIncluded: @escaping (U.T.Iterator.Element) -> Bool) -> CancellablePromise<[U.T.Iterator.Element]> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return filterValues(on: dispatcher, isIncluded)
    }
}

public extension CancellableThenable where U.T: Collection {
    func firstValue(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, where test: @escaping (U.T.Iterator.Element) -> Bool) -> CancellablePromise<U.T.Iterator.Element> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return firstValue(on: dispatcher, where: test)
    }
}

public extension CancellableThenable where U.T: Sequence, U.T.Iterator.Element: Comparable {
    /// - Returns: a cancellable promise fulfilled with the sorted values of this `Sequence`.
    func sortedValues(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil) -> CancellablePromise<[U.T.Iterator.Element]> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return sortedValues(on: dispatcher)
    }
}

public extension CancellableCatchMixin {
    /**
     The provided closure executes when this cancellable promise rejects.
     
     Rejecting a promise cascades: rejecting all subsequent promises (unless
     recover is invoked) thus you will typically place your catch at the end
     of a chain. Often utility promises will not have a catch, instead
     delegating the error handling to the caller.
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter policy: The default policy does not execute your handler for cancellation errors.
     - Parameter body: The handler to execute if this promise is rejected.
     - Returns: A promise finalizer.
     - SeeAlso: [Cancellation](https://github.com/mxcl/PromiseKit/blob/master/Documentation/CommonPatterns.md#cancellation)
     */
    @discardableResult
    func `catch`(on: DispatchQueue? = conf.Q.return, flags: DispatchWorkItemFlags? = nil, policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(Error) -> Void) -> CancellableFinalizer {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.return, flags: flags)
        return `catch`(on: dispatcher, policy: policy, body)
    }
    
    /**
     The provided closure executes when this cancellable promise rejects.
     
     Unlike `catch`, `recover` continues the chain.
     Use `recover` in circumstances where recovering the chain from certain errors is a possibility. For example:

         let context = firstly {
             CLLocationManager.requestLocation()
         }.recover { error in
             guard error == CLError.unknownLocation else { throw error }
             return .value(CLLocation.chicago)
         }.cancelContext
     
         //…
     
         context.cancel()
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter policy: The default policy does not execute your handler for cancellation errors.
     - Parameter body: The handler to execute if this promise is rejected.
     - SeeAlso: [Cancellation](https://github.com/mxcl/PromiseKit/blob/master/Documentation/CommonPatterns.md#cancellation)
     */
    func recover<V: CancellableThenable>(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(Error) throws -> V) -> CancellablePromise<C.T> where V.U.T == C.T {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return recover(on: dispatcher, policy: policy, body)
    }
    
    /**
     The provided closure executes when this cancellable promise rejects.
     
     Unlike `catch`, `recover` continues the chain.
     Use `recover` in circumstances where recovering the chain from certain errors is a possibility. For example:

         let context = firstly {
             CLLocationManager.requestLocation()
         }.recover { error in
             guard error == CLError.unknownLocation else { throw error }
             return .value(CLLocation.chicago)
         }.cancelContext
     
         //…
     
         context.cancel()
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter policy: The default policy does not execute your handler for cancellation errors.
     - Parameter body: The handler to execute if this promise is rejected.
     - SeeAlso: [Cancellation](https://github.com/mxcl/PromiseKit/blob/master/Documentation/CommonPatterns.md#cancellation)
     - Note: Methods with the `cancellable` prefix create a new CancellablePromise, and those without the `cancellable` prefix accept an existing CancellablePromise.
     */
    func cancellableRecover<V: Thenable>(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(Error) throws -> V) -> CancellablePromise<C.T> where V.T == C.T {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return cancellableRecover(on: dispatcher, body)
    }

    /**
     The provided closure executes when this cancellable promise resolves, whether it rejects or not.
     
         let context = firstly {
             UIApplication.shared.networkActivityIndicatorVisible = true
             //…  returns a cancellable promise
         }.done {
             //…
         }.ensure {
             UIApplication.shared.networkActivityIndicatorVisible = false
         }.catch {
             //…
         }.cancelContext
     
         //…
     
         context.cancel()

     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The closure that executes when this promise resolves.
     - Returns: A new promise, resolved with this promise’s resolution.
     */
    func ensure(on: DispatchQueue? = conf.Q.return, flags: DispatchWorkItemFlags? = nil, _ body: @escaping () -> Void) -> CancellablePromise<C.T> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.return, flags: flags)
        return ensure(on: dispatcher, body)
    }
    
    /**
     The provided closure executes when this cancellable promise resolves, whether it rejects or not.
     The chain waits on the returned `CancellablePromise<Void>`.

         let context = firstly {
             setup() // returns a cancellable promise
         }.done {
             //…
         }.ensureThen {
             teardown()  // -> CancellablePromise<Void>
         }.catch {
             //…
         }.cancelContext
     
         //…
     
         context.cancel()

     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The closure that executes when this promise resolves.
     - Returns: A new cancellable promise, resolved with this promise’s resolution.
     */
    func ensureThen(on: DispatchQueue? = conf.Q.return, flags: DispatchWorkItemFlags? = nil, _ body: @escaping () -> CancellablePromise<Void>) -> CancellablePromise<C.T> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.return, flags: flags)
        return ensureThen(on: dispatcher, body)
    }
}

public extension CancellableFinalizer {
    /// `finally` is the same as `ensure`, but it is not chainable
    @discardableResult
    func finally(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ body: @escaping () -> Void) -> CancelContext {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.return, flags: flags)
        return finally(on: dispatcher, body)
    }
}

public extension CancellableCatchMixin where C.T == Void {
    /**
     The provided closure executes when this cancellable promise rejects.
     
     This variant of `recover` ensures that no error is thrown from the handler and allows specifying a catch policy.
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter policy: The default policy does not execute your handler for cancellation errors.
     - Parameter body: The handler to execute if this promise is rejected.
     - SeeAlso: [Cancellation](https://github.com/mxcl/PromiseKit/blob/master/Documentation/CommonPatterns.md#cancellation)
     */
    func recover(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, policy: CatchPolicy = conf.catchPolicy, _ body: @escaping(Error) throws -> Void) -> CancellablePromise<Void> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return recover(on: dispatcher, policy: policy, body)
    }
}
