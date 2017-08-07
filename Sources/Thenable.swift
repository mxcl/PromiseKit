import Dispatch


//TODO fire off a message to the Queue's runloop to avoid zalgo
// if no runloop, show warning about zalgo
// in case of `nil` don't do that and also don't dispatch to queue later
// in caes of `main` we can optimize and avoid a dispatch if we're on the main queue and zalgo was avoided


public protocol Thenable: class {
    associatedtype T
    func pipe(to: @escaping(Result<T>) -> Void)
    var result: Result<T>? { get }
}

public extension Thenable {
    public func then<U: Thenable>(on: DispatchQueue? = conf.Q.map, file: StaticString = #file, line: UInt = #line, _ body: @escaping(T) throws -> U) -> Promise<U.T> {
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

    func flatMap<U>(on: DispatchQueue? = conf.Q.map, _ transform: @escaping(T) throws -> U?) -> Promise<U> {
        let rp = Promise<U>(.pending)
        pipe {
            switch $0 {
            case .fulfilled(let value):
                on.async {
                    do {
                        if let rv = try transform(value) {
                            rp.box.seal(.fulfilled(rv))
                        } else {
                            throw PMKError.flatMap(value, U.self)
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

    /// Immutably access the fulfilled value; the returned Promise maintains that value.
    func get(_ body: @escaping (T) throws -> Void) -> Promise<T> {
        return map(on: PromiseKit.conf.Q.return) {
            try body($0)
            return $0
        }
    }

    public func asVoid() -> Promise<Void> {
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
    func map<U>(on: DispatchQueue? = conf.Q.map, _ transform: @escaping(T.Iterator.Element) throws -> U) -> Promise<[U]> {
        return map(on: on){ try $0.map(transform) }
    }

    func thenMap<U: Thenable>(on: DispatchQueue? = conf.Q.map, _ transform: @escaping(T.Iterator.Element) throws -> U) -> Promise<[U.T]> {
        return then(on: on) {
            when(fulfilled: try $0.map(transform))
        }
    }

    func flatMap<U>(on: DispatchQueue? = conf.Q.map, _ transform: @escaping(T.Iterator.Element) throws -> U?) -> Promise<[U]> {
        return map(on: on){ try $0.flatMap(transform) }
    }

    func thenFlatMap<U: Thenable>(on: DispatchQueue? = conf.Q.map, _ transform: @escaping(T.Iterator.Element) throws -> U) -> Promise<[U.T.Iterator.Element]> where U.T: Sequence {
        return then(on: on){
            when(fulfilled: try $0.map(transform))
        }.map(on: nil) {
            $0.flatMap{ $0 }
        }
    }

    func filter(on: DispatchQueue? = conf.Q.map, test: @escaping (T.Iterator.Element) -> Bool) -> Promise<[T.Iterator.Element]> {
        return map(on: on) { $0.filter(test) }
    }
}

public extension Thenable where T: Collection {
    var first: Promise<T.Iterator.Element> {
        return map(on: nil) { aa in
            if let a1 = aa.first {
                return a1
            } else {
                throw PMKError.badInput
            }
        }
    }

    var last: Promise<T.Iterator.Element> {
        return map(on: nil) { aa in
            if aa.isEmpty {
                throw PMKError.badInput
            } else {
                let i = aa.index(aa.endIndex, offsetBy: -1)
                return aa[i]
            }
        }
    }
}

public extension Thenable where T: Sequence, T.Iterator.Element: Comparable {
    func sorted(on: DispatchQueue? = conf.Q.map) -> Promise<[T.Iterator.Element]> {
        return map(on: on){ $0.sorted() }
    }
}
