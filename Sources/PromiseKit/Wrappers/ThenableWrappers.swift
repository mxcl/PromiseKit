import Dispatch

public extension _PMKSharedWrappers {

    /**
     The provided closure is executed when this promise is resolved.
     
     Equivalent to `map { x -> Void in`, but since we force the `Void` return Swift
     is happier and gives you less hassle about your closure’s qualification.
     
           firstly {
               URLSession.shared.dataTask(.promise, with: url)
           }.done { response in
               print(response.data)
           }

     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter flags: `DispatchWorkItemFlags` to be applied when dispatching.
     - Parameter body: The closure that is executed when this Promise is fulfilled.
     - Returns: A new promise fulfilled as `Void`.
     */
    @_disfavoredOverload
    func done(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ body: @escaping(T) throws -> Void) -> BaseOfVoid {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.return, flags: flags)
        return done(on: dispatcher, body)
    }

    /**
     The provided closure is executed when this promise is resolved.
     
     This is like `done` but it returns the same value that the handler is fed.
     `get` immutably accesses the fulfilled value; the returned Promise maintains that value.
     
         firstly {
            .value(1)
         }.get { foo in
            print(foo, " is 1")
         }.done { foo in
            print(foo, " is 1")
         }.done { foo in
            print(foo, " is Void")
         }

     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter flags: `DispatchWorkItemFlags` to be applied when dispatching.
     - Parameter body: The closure that is executed when this Promise is fulfilled.
     - Returns: A new promise that is resolved with the value that the handler is fed.
     */
    @_disfavoredOverload
    func get(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ body: @escaping (T) throws -> Void) -> BaseOfT {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.return, flags: flags)
        return get(on: dispatcher, body)
    }

    /**
     The provided closure is executed with promise result.
 
     This is like `get` but provides the Result<T> of the Promise so you can inspect the value of the chain at this point without causing any side effects.
 
         promise.tap{ print($0) }.then{ /*…*/ }

     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter flags: `DispatchWorkItemFlags` to be applied when dispatching.
     - Parameter body: The closure that is executed with Result of Promise.
     - Returns: A new promise that is resolved with the result that the handler is fed.
     */
    @_disfavoredOverload
    func tap(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ body: @escaping(Result<T, Error>) -> Void) -> BaseOfT {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return tap(on: dispatcher, body)
    }
}

public extension Thenable {
    
    /**
     The provided closure executes when this promise resolves.
     
     This allows chaining promises. The promise returned by the provided closure is resolved before the promise returned by this closure resolves.

         firstly {
            URLSession.shared.dataTask(.promise, with: url1)
         }.then { response in
            transform(data: response.data)
         }.done { transformation in
            //…
         }

     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter flags: `DispatchWorkItemFlags` to be applied when dispatching.
     - Parameter body: The closure that executes when this promise fulfills. It must return a promise.
     - Returns: A new promise that resolves when the promise returned from the provided closure resolves.
     */
    @_disfavoredOverload
    func then<U: Thenable>(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ body: @escaping(T) throws -> U) -> Promise<U.T> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return then(on: dispatcher, body)
    }
    
    /**
     The provided closure is executed when this promise is resolved.
     
     This is like `then` but it requires the closure to return a non-promise.
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter flags: `DispatchWorkItemFlags` to be applied when dispatching.
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
    @_disfavoredOverload
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
    @_disfavoredOverload
    func compactMap<U>(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping(T) throws -> U?) -> Promise<U> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return compactMap(on: dispatcher, transform)
    }
}

public extension CancellableThenable {
    
    /**
     The provided closure executes when this cancellable promise resolves.
     
     This allows chaining promises. The cancellable promise returned by the provided closure is resolved before the cancellable promise returned by this closure resolves.

         let context = firstly {
            URLSession.shared.dataTask(.promise, with: url1)
         }.cancellize().then { response in
            transform(data: response.data) // returns a CancellablePromise
         }.done { transformation in
            //…
         }.cancelContext
         //…
         context.cancel()

     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter flags: `DispatchWorkItemFlags` to be applied when dispatching.
     - Parameter body: The closure that executes when this cancellable promise fulfills. It must return a cancellable promise.
     - Returns: A new cancellable promise that resolves when the promise returned from the provided closure resolves.
     */
    @_disfavoredOverload
    func then<V: CancellableThenable>(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ body: @escaping (U.T) throws -> V) -> CancellablePromise<V.U.T> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return then(on: dispatcher, body)
    }
    
    /**
     The provided closure executes when this cancellable promise resolves.
     
     This allows chaining promises. The promise returned by the provided closure is resolved before the cancellable promise returned by this closure resolves.

         let context = firstly {
            URLSession.shared.dataTask(.promise, with: url1)
         }.cancellize().then { response in
            transform(data: response.data) // returns a Promise
         }.done { transformation in
            //…
         }.cancelContext
         //…
         context.cancel()

     - Parameter on: The dispatcher that executes the provided closure.
     - Parameter flags: `DispatchWorkItemFlags` to be applied when dispatching.
     - Parameter body: The closure that executes when this cancellable promise fulfills. It must return a promise (not a cancellable promise).
     - Returns: A new cancellable promise that resolves when the promise returned from the provided closure resolves.
     */
    @_disfavoredOverload
    func then<V: Thenable>(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ body: @escaping (U.T) throws -> V) -> CancellablePromise<V.T> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return then(on: dispatcher, body)
    }
    
    /**
     The provided closure is executed when this cancellable promise is resolved.
     
     This is like `then` but it requires the closure to return a non-promise and non-cancellable-promise.
     
         let context = firstly {
            URLSession.shared.dataTask(.promise, with: url1)
         }.cancellize().map { response in
            response.data.length
         }.done { length in
            //…
         }.cancelContext
         //…
         context.cancel()

     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter flags: `DispatchWorkItemFlags` to be applied when dispatching.
     - Parameter transform: The closure that is executed when this CancellablePromise is fulfilled. It must return a non-promise and non-cancellable-promise.
     - Returns: A new cancellable promise that is resolved with the value returned from the provided closure.
     */
    @_disfavoredOverload
    func map<V>(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping (U.T) throws -> V) -> CancellablePromise<V> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return map(on: dispatcher, transform)
    }
    
    /**
     The provided closure is executed when this cancellable promise is resolved.
     
     In your closure return an `Optional`, if you return `nil` the resulting cancellable promise is rejected
     with `PMKError.compactMap`, otherwise the cancellable promise is fulfilled with the unwrapped value.
     
         let context = firstly {
            URLSession.shared.dataTask(.promise, with: url)
         }.cancellize().compactMap {
            try JSONSerialization.jsonObject(with: $0.data) as? [String: String]
         }.done { dictionary in
            //…
         }.catch {
            // either `PMKError.compactMap` or a `JSONError`
         }.cancelContext
         //…
         context.cancel()
     */
    @_disfavoredOverload
    func compactMap<V>(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping (U.T) throws -> V?) -> CancellablePromise<V> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return compactMap(on: dispatcher, transform)
    }
}

