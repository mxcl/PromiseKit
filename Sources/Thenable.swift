import Dispatch

public protocol Thenable: class {
    associatedtype T
    func pipe(to: @escaping(Result<T>) -> Void)
    var result: Result<T>? { get }
}

public extension Thenable {
    
    /**
     The provided closure executes when this promise resolves.
     
     This allows chaining promises. The promise returned by the provided closure is resolved before the promise returned by this closure resolves.
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The closure that executes when this promise fulfills. It must return a promise.
     - Returns: A new promise that resolves when the promise returned from the provided closure resolves. For example:
     
         URLSession.GET(url1).then { data in
            return CLLocationManager.promise()
         }.done { location in
            //…
         }
     */
    func then<U: Thenable>(on: DispatchQueue? = conf.Q.map, file: StaticString = #file, line: UInt = #line, _ body: @escaping(T) throws -> U) -> Promise<U.T> {
        let rp = Promise<U.T>(.pending)
        pipe {
            switch $0 {
            case .fulfilled(let value):
                on.async {
                    do {
                        let rv = try body(value)
                        guard rv !== rp else { throw PMKError.returnedSelf }
                        rv.pipe(to: rp.box.seal)
                    } catch {
                        rp.box.seal(.rejected(error))
                    }
                }
            case .rejected(let error):
                rp.box.seal(.rejected(error))
            }
        }
        return rp
    }

    /**
     The provided closure is executed when this promise is resolved.
     
     This is like `then` but it requires the closure to return a non-promise.
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter transform: The closure that is executed when this Promise is fulfilled. It must return a non-promise.
     - Returns: A new promise that is resolved with the value returned from the provided closure. For example:
     
         URLSession.GET(url).then { data -> Int in
            return data.length
         }.done { length in
            //…
         }
     */
    func map<U>(on: DispatchQueue? = conf.Q.map, _ transform: @escaping(T) throws -> U) -> Promise<U> {
        let rp = Promise<U>(.pending)
        pipe {
            switch $0 {
            case .fulfilled(let value):
                on.async {
                    do {
                        rp.box.seal(.fulfilled(try transform(value)))
                    } catch {
                        rp.box.seal(.rejected(error))
                    }
                }
            case .rejected(let error):
                rp.box.seal(.rejected(error))
            }
        }
        return rp
    }

    /**
         firstly {
             URLSession.shared.dataTask(.promise, with: url)
         }.compactMap {
             try JSONSerialization.jsonObject(with: $0.data) as? [String: String]
         }.done { result in
             //…
         }.catch {
             // closure to `compactMap` threw or returned `nil`
         }
     */
    func compactMap<U>(on: DispatchQueue? = conf.Q.map, _ transform: @escaping(T) throws -> U?) -> Promise<U> {
        let rp = Promise<U>(.pending)
        pipe {
            switch $0 {
            case .fulfilled(let value):
                on.async {
                    do {
                        if let rv = try transform(value) {
                            rp.box.seal(.fulfilled(rv))
                        } else {
                            throw PMKError.compactMap(value, U.self)
                        }
                    } catch {
                        rp.box.seal(.rejected(error))
                    }
                }
            case .rejected(let error):
                rp.box.seal(.rejected(error))
            }
        }
        return rp
    }

    /**
     The provided closure is executed when this promise is resolved.
     
     This is like `then` but it returns a `Void` promise.
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter body: The closure that is executed when this Promise is fulfilled.
     - Returns: A new promise that is resolved with a Void value. For example:
     
         URLSession.GET(url).done { data in
            print(data)
         }
     */
    func done(on: DispatchQueue? = conf.Q.return, _ body: @escaping(T) throws -> Void) -> Promise<Void> {
        let rp = Promise<Void>(.pending)
        pipe {
            switch $0 {
            case .fulfilled(let value):
                on.async {
                    do {
                        try body(value)
                        rp.box.seal(.fulfilled(()))
                    } catch {
                        rp.box.seal(.rejected(error))
                    }
                }
            case .rejected(let error):
                rp.box.seal(.rejected(error))
            }
        }
        return rp
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
         }
     */
    func get(_ body: @escaping (T) throws -> Void) -> Promise<T> {
        return map(on: PromiseKit.conf.Q.return) {
            try body($0)
            return $0
        }
    }

    func asVoid() -> Promise<Void> {
        return map(on: nil) { _ in }
    }
}

public extension Thenable {
    /**
     - Returns: The error with which this promise was rejected; `nil` if this promise is not rejected.
     */
    var error: Error? {
        switch result {
        case .none:
            return nil
        case .some(.fulfilled):
            return nil
        case .some(.rejected(let error)):
            return error
        }
    }

    /**
     - Returns: `true` if the promise has not yet resolved.
     */
    var isPending: Bool {
        return result == nil
    }

    /**
     - Returns: `true` if the promise has resolved.
     */
    var isResolved: Bool {
        return !isPending
    }

    /**
     - Returns: `true` if the promise was fulfilled.
     */
    var isFulfilled: Bool {
        return value != nil
    }

    /**
     - Returns: `true` if the promise was rejected.
     */
    var isRejected: Bool {
        return error != nil
    }

    /**
     - Returns: The value with which this promise was fulfilled or `nil` if this promise is pending or rejected.
     */
    var value: T? {
        switch result {
        case .none:
            return nil
        case .some(.fulfilled(let value)):
            return value
        case .some(.rejected):
            return nil
        }
    }
}

public extension Thenable where T: Sequence {
    func mapValues<U>(on: DispatchQueue? = conf.Q.map, _ transform: @escaping(T.Iterator.Element) throws -> U) -> Promise<[U]> {
        return map(on: on){ try $0.map(transform) }
    }

    func flatMapValues<U: Sequence>(on: DispatchQueue? = conf.Q.map, _ transform: @escaping(T.Iterator.Element) throws -> U) -> Promise<[U.Iterator.Element]> {
        return map(on: on){ (foo: T) in
            try foo.flatMap{ try transform($0) }
        }
    }

    func compactMapValues<U>(on: DispatchQueue? = conf.Q.map, _ transform: @escaping(T.Iterator.Element) throws -> U?) -> Promise<[U]> {
        return map(on: on) { foo -> [U] in
          #if !swift(>=3.3) || (swift(>=4) && !swift(>=4.1))
            return try foo.flatMap(transform)
          #else
            return try foo.compactMap(transform)
          #endif
        }
    }

    func thenMap<U: Thenable>(on: DispatchQueue? = conf.Q.map, _ transform: @escaping(T.Iterator.Element) throws -> U) -> Promise<[U.T]> {
        return then(on: on) {
            when(fulfilled: try $0.map(transform))
        }
    }

    func thenFlatMap<U: Thenable>(on: DispatchQueue? = conf.Q.map, _ transform: @escaping(T.Iterator.Element) throws -> U) -> Promise<[U.T.Iterator.Element]> where U.T: Sequence {
        return then(on: on) {
            when(fulfilled: try $0.map(transform))
        }.map(on: nil) {
            $0.flatMap{ $0 }
        }
    }

    func filterValues(on: DispatchQueue? = conf.Q.map, _ isIncluded: @escaping (T.Iterator.Element) -> Bool) -> Promise<[T.Iterator.Element]> {
        return map(on: on) {
            $0.filter(isIncluded)
        }
    }
}

public extension Thenable where T: Collection {
    var firstValue: Promise<T.Iterator.Element> {
        return map(on: nil) { aa in
            if let a1 = aa.first {
                return a1
            } else {
                throw PMKError.emptySequence
            }
        }
    }

    var lastValue: Promise<T.Iterator.Element> {
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

public extension Thenable where T: Sequence, T.Iterator.Element: Comparable {
    func sortedValues(on: DispatchQueue? = conf.Q.map) -> Promise<[T.Iterator.Element]> {
        return map(on: on){ $0.sorted() }
    }
}
