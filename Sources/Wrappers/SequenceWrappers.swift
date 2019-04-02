import Dispatch

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

public extension CancellableThenable where U.T: Sequence {
    /**
     `CancellablePromise<[U.T]>` => `U.T` -> `V` => `CancellablePromise<[V]>`

         firstly {
             cancellize(Promise.value([1,2,3]))
         }.mapValues { integer in
             integer * 2
         }.done {
             // $0 => [2,4,6]
         }
     */
    func mapValues<V>(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping(U.T.Iterator.Element) throws -> V) -> CancellablePromise<[V]> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return mapValues(on: dispatcher, transform)
    }

    /**
     `CancellablePromise<[U.T]>` => `U.T` -> `[V]` => `CancellablePromise<[V]>`

         firstly {
             cancellize(Promise.value([1,2,3]))
         }.flatMapValues { integer in
             [integer, integer]
         }.done {
             // $0 => [1,1,2,2,3,3]
         }
     */
    func flatMapValues<V: Sequence>(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping(U.T.Iterator.Element) throws -> V) -> CancellablePromise<[V.Iterator.Element]> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return flatMapValues(on: dispatcher, transform)
    }

    /**
     `CancellablePromise<[U.T]>` => `U.T` -> `V?` => `CancellablePromise<[V]>`

         firstly {
             cancellize(Promise.value(["1","2","a","3"]))
         }.compactMapValues {
             Int($0)
         }.done {
             // $0 => [1,2,3]
         }
     */
    func compactMapValues<V>(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping(U.T.Iterator.Element) throws -> V?) -> CancellablePromise<[V]> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return compactMapValues(on: dispatcher, transform)
    }

    /**
     `CancellablePromise<[U.T]>` => `U.T` -> `CancellablePromise<V>` => `CancellablePromise<[V]>`

         firstly {
             cancellize(Promise.value([1,2,3]))
         }.thenMap { integer in
             cancellize(Promise.value(integer * 2))
         }.done {
             // $0 => [2,4,6]
         }
     */
    func thenMap<V: CancellableThenable>(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping(U.T.Iterator.Element) throws -> V) -> CancellablePromise<[V.U.T]> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return thenMap(on: dispatcher, transform)
    }

    /**
     `CancellablePromise<[U.T]>` => `U.T` -> `Promise<V>` => `CancellablePromise<[V]>`

         firstly {
             Promise.value([1,2,3])
         }.cancellize().thenMap { integer in
             .value(integer * 2)
         }.done {
             // $0 => [2,4,6]
         }
     */
    func thenMap<V: Thenable>(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping(U.T.Iterator.Element) throws -> V) -> CancellablePromise<[V.T]> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return thenMap(on: dispatcher, transform)
    }

    /**
     `CancellablePromise<[T]>` => `T` -> `CancellablePromise<[U]>` => `CancellablePromise<[U]>`

         firstly {
             cancellize(Promise.value([1,2,3]))
         }.thenFlatMap { integer in
             cancellize(Promise.value([integer, integer]))
         }.done {
             // $0 => [1,1,2,2,3,3]
         }
     */
    func thenFlatMap<V: CancellableThenable>(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping(U.T.Iterator.Element) throws -> V) -> CancellablePromise<[V.U.T.Iterator.Element]> where V.U.T: Sequence {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return thenFlatMap(on: dispatcher, transform)
    }

    /**
     `CancellablePromise<[T]>` => `T` -> `Promise<[U]>` => `CancellablePromise<[U]>`

         firstly {
             Promise.value([1,2,3])
         }.cancellize().thenFlatMap { integer in
             .value([integer, integer])
         }.done {
             // $0 => [1,1,2,2,3,3]
         }
     */
    func thenFlatMap<V: Thenable>(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping(U.T.Iterator.Element) throws -> V) -> CancellablePromise<[V.T.Iterator.Element]> where V.T: Sequence {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return thenFlatMap(on: dispatcher, transform)
    }

    /**
     `CancellablePromise<[T]>` => `T` -> Bool => `CancellablePromise<[U]>`

         firstly {
             cancellize(Promise.value([1,2,3]))
         }.filterValues {
             $0 > 1
         }.done {
             // $0 => [2,3]
         }
     */
    func filterValues(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ isIncluded: @escaping (U.T.Iterator.Element) -> Bool) -> CancellablePromise<[U.T.Iterator.Element]> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return filterValues(on: dispatcher, isIncluded)
    }
}

public extension CancellableThenable where U.T: Collection {
    func firstValue(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, where test: @escaping (U.T.Iterator.Element) -> Bool) -> CancellablePromise<U.T.Iterator.Element> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return firstValue(on: dispatcher, where: test)
    }
}

public extension CancellableThenable where U.T: Sequence, U.T.Iterator.Element: Comparable {
    /// - Returns: a cancellable promise fulfilled with the sorted values of this `Sequence`.
    func sortedValues(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil) -> CancellablePromise<[U.T.Iterator.Element]> {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.map, flags: flags)
        return sortedValues(on: dispatcher)
    }
}


