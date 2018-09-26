import Dispatch

/**
 CancellableThenable represents an asynchronous operation that can be both chained and cancelled.  When chained, all CancellableThenable members of the chain are cancelled when `cancel` is called on the associated CancelContext.
 */
public protocol CancellableThenable: class {
    /// Type of the delegate `thenable`
    associatedtype U: Thenable
    
    /// Delegate `thenable` for this `CancellableThenable`
    var thenable: U { get }

    /// The `CancelContext` associated with this `CancellableThenable`
    var cancelContext: CancelContext { get }
    
    /// Tracks the cancel items for this `CancellableThenable`.  These items are removed from the associated `CancelContext` when the thenable resolves.
    var cancelItemList: CancelItemList { get }
}

public extension CancellableThenable {
    /// Append the `task` and `reject` function for a cancellable task to the cancel context
    func appendCancellableTask(_ task: CancellableTask?, reject: ((Error) -> Void)?) {
        self.cancelContext.append(task: task, reject: reject, thenable: self)
    }
    
    /// Append the cancel context associated with `from` to our cancel context.  Typically `from` is a branch of our chain.
    func appendCancelContext<Z: CancellableThenable>(from: Z) {
        self.cancelContext.append(context: from.cancelContext, thenable: self)
    }
    
    /**
     Cancel all members of the promise chain and their associated asynchronous operations.

     - Parameter error: Specifies the cancellation error to use for the cancel operation, defaults to `PMKError.cancelled`
     */
    func cancel(error: Error? = nil) {
        self.cancelContext.cancel(error: error)
    }
    
    /**
     True if all members of the promise chain have been successfully cancelled, false otherwise.
     */
    var isCancelled: Bool {
        return self.cancelContext.isCancelled
    }
    
    /**
     True if `cancel` has been called on the CancelContext associated with this promise, false otherwise.  `cancelAttempted` will be true if `cancel` is called on any promise in the chain.
     */
    var cancelAttempted: Bool {
        return self.cancelContext.cancelAttempted
    }
    
    /**
     The cancellation error generated when the promise is cancelled, or `nil` if not cancelled.
     */
    var cancelledError: Error? {
        return self.cancelContext.cancelledError
    }
    
    /**
     The provided closure executes when this cancellable promise resolves.  This allows chaining cancellable promises.
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The closure that executes when this cancellable promise fulfills. It must return a cancellable promise.
     - Returns: A new cancellable promise that resolves when the cancellable promise returned from the provided closure resolves. For example:

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

        let cancelItemList = CancelItemList()
        
        let cancelBody = { (value: U.T) throws -> V.U in
            if let error = self.cancelContext.removeItems(self.cancelItemList, clearList: true) {
                throw error
            } else {
                let rv = try body(value)
                self.cancelContext.append(context: rv.cancelContext, thenableCancelItemList: cancelItemList)
                return rv.thenable
            }
        }
        
        let promise = self.thenable.then(on: on, flags: flags, cancelBody)
        return CancellablePromise(promise: promise, context: self.cancelContext, cancelItemList: cancelItemList)
    }
    
    /**
     The provided closure executes when this cancellable promise resolves.  This allows chaining  promises and cancellable promises.
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The closure that executes when this cancellable promise fulfills. It must return a promise (not a cancellable promise).
     - Returns: A new cancellable promise that resolves when the promise returned from the provided closure resolves. For example:

           let context = firstly {
               URLSession.shared.cancellableDataTask(.promise, with: url1)
           }.then { response in
               transform(data: response.data) // returns a Promise
           }.done { transformation in
               //…
           }.cancelContext
     
           //…
     
           context.cancel()
     */
    func cancellableThen<V: Thenable>(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, _ body: @escaping (U.T) throws -> V) -> CancellablePromise<V.T> {
        let cancelBody = { (value: U.T) throws -> V in
            if let error = self.cancelContext.removeItems(self.cancelItemList, clearList: true) {
                throw error
            } else {
                return try body(value)
            }
        }
        
        let promise = self.thenable.then(on: on, flags: flags, cancelBody)
        return CancellablePromise(promise, cancelContext: self.cancelContext)
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
        let cancelTransform = { (value: U.T) throws -> V in
            if let error = self.cancelContext.removeItems(self.cancelItemList, clearList: true) {
                throw error
            } else {
                return try transform(value)
            }
        }
        
        let promise = self.thenable.map(on: on, flags: flags, cancelTransform)
        return CancellablePromise(promise: promise, context: self.cancelContext)
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
        let cancelTransform = { (value: U.T) throws -> V? in
            if let error = self.cancelContext.removeItems(self.cancelItemList, clearList: true) {
                throw error
            } else {
                return try transform(value)
            }
        }
        
        let promise = self.thenable.compactMap(on: on, flags: flags, cancelTransform)
        return CancellablePromise(promise: promise, context: self.cancelContext)
    }
    
    /**
     The provided closure is executed when this cancellable promise is resolved.
     
     Equivalent to `map { x -> Void in`, but since we force the `Void` return Swift
     is happier and gives you less hassle about your closure’s qualification.
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The closure that is executed when this CancellablePromise is fulfilled.
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
        let cancelBody = { (value: U.T) throws -> Void in
            if let error = self.cancelContext.removeItems(self.cancelItemList, clearList: true) {
                throw error
            } else {
                try body(value)
            }
        }
        
        let promise = self.thenable.done(on: on, flags: flags, cancelBody)
        return CancellablePromise(promise: promise, context: self.cancelContext)
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
        return map(on: on, flags: flags) {
            try body($0)
            return $0
        }
    }

    /**
     The provided closure is executed with cancellable promise result.

     This is like `get` but provides the Result<T> of the CancellablePromise so you can inspect the value of the chain at this point without causing any side effects.

     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The closure that is executed with Result of CancellablePromise.
     - Returns: A new cancellable promise that is resolved with the result that the handler is fed. For example:

     promise.tap{ print($0) }.then{ /*…*/ }
     */
    func tap(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, _ body: @escaping(Result<U.T>) -> Void) -> CancellablePromise<U.T> {
        let rp = CancellablePromise<U.T>.pending()
        rp.promise.cancelContext = self.cancelContext
        self.thenable.pipe { result in
            on.async(flags: flags) {
                if let error = self.cancelContext.removeItems(self.cancelItemList, clearList: true) {
                    rp.resolver.reject(error)
                } else {
                    body(result)
                    rp.resolver.resolve(result)
                }
            }
        }
        return rp.promise
    }

    /// - Returns: a new cancellable promise chained off this cancellable promise but with its value discarded.
    func asVoid() -> CancellablePromise<Void> {
        return map(on: nil) { _ in }
    }
}

public extension CancellableThenable {
    /**
     - Returns: The error with which this cancellable promise was rejected; `nil` if this promise is not rejected.
     */
    var error: Error? {
        return thenable.error
    }

    /**
     - Returns: `true` if the cancellable promise has not yet resolved.
     */
    var isPending: Bool {
        return thenable.isPending
    }

    /**
     - Returns: `true` if the cancellable promise has resolved.
     */
    var isResolved: Bool {
        return thenable.isResolved
    }

    /**
     - Returns: `true` if the cancellable promise was fulfilled.
     */
    var isFulfilled: Bool {
        return thenable.isFulfilled
    }

    /**
     - Returns: `true` if the cancellable promise was rejected.
     */
    var isRejected: Bool {
        return thenable.isRejected
    }

    /**
     - Returns: The value with which this cancellable promise was fulfilled or `nil` if this cancellable promise is pending or rejected.
     */
    var value: U.T? {
        return thenable.value
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
        return map(on: on, flags: flags) { try $0.map(transform) }
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
        return map(on: on, flags: flags) { (foo: U.T) in
            try foo.flatMap { try transform($0) }
        }
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
        return map(on: on, flags: flags) { foo -> [V] in
          #if !swift(>=3.3) || (swift(>=4) && !swift(>=4.1))
            return try foo.flatMap(transform)
          #else
            return try foo.compactMap(transform)
          #endif
        }
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
        return then(on: on, flags: flags) {
            when(fulfilled: try $0.map(transform))
        }
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
        return cancellableThen(on: on, flags: flags) {
            when(fulfilled: try $0.map(transform))
        }
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
        return then(on: on, flags: flags) {
            when(fulfilled: try $0.map(transform))
        }.map(on: nil) {
            $0.flatMap { $0 }
        }
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
        return cancellableThen(on: on, flags: flags) {
            when(fulfilled: try $0.map(transform))
        }.map(on: nil) {
            $0.flatMap { $0 }
        }
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
        return map(on: on, flags: flags) {
            $0.filter(isIncluded)
        }
    }
}

public extension CancellableThenable where U.T: Collection {
    /// - Returns: a cancellable promise fulfilled with the first value of this `Collection` or, if empty, a promise rejected with PMKError.emptySequence.
    var firstValue: CancellablePromise<U.T.Iterator.Element> {
        return map(on: nil) { aa in
            if let a1 = aa.first {
                return a1
            } else {
                throw PMKError.emptySequence
            }
        }
    }

    func firstValue(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, where test: @escaping (U.T.Iterator.Element) -> Bool) -> CancellablePromise<U.T.Iterator.Element> {
        return map(on: on, flags: flags) {
            for x in $0 where test(x) {
                return x
            }
            throw PMKError.emptySequence
        }
    }

    /// - Returns: a cancellable promise fulfilled with the last value of this `Collection` or, if empty, a promise rejected with PMKError.emptySequence.
    var lastValue: CancellablePromise<U.T.Iterator.Element> {
        return map(on: nil) { aa in
            if aa.isEmpty {
                throw PMKError.emptySequence
            } else {
                let i = aa.index(aa.endIndex, offsetBy: -1)
                return aa[i]
            }
        }
    }
}

public extension CancellableThenable where U.T: Sequence, U.T.Iterator.Element: Comparable {
    /// - Returns: a cancellable promise fulfilled with the sorted values of this `Sequence`.
    func sortedValues(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil) -> CancellablePromise<[U.T.Iterator.Element]> {
        return map(on: on, flags: flags) { $0.sorted() }
    }
}
