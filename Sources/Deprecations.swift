import Dispatch

@available(*, deprecated: 5.0)
public func wrap<T>(_ body: (@escaping (T?, Error?) -> Void) throws -> Void) -> Promise<T> {
    return Promise { seal in
        try body(seal.resolve)
    }
}

@available(*, deprecated: 5.0)
public func wrap<T>(_ body: (@escaping (T, Error?) -> Void) throws -> Void) -> Promise<T>  {
    return Promise { seal in
        try body(seal.resolve)
    }
}

@available(*, deprecated: 5.0)
public func wrap<T>(_ body: (@escaping (Error?, T?) -> Void) throws -> Void) -> Promise<T> {
    return Promise { seal in
        try body(seal.resolve)
    }
}

@available(*, deprecated: 5.0)
public func wrap(_ body: (@escaping (Error?) -> Void) throws -> Void) -> Promise<Void> {
    return Promise { seal in
        try body(seal.resolve)
    }
}

@available(*, deprecated: 5.0)
public func wrap<T>(_ body: (@escaping (T) -> Void) throws -> Void) -> Promise<T> {
    return Promise { seal in
        try body(seal.fulfill)
    }
}

public extension Promise {
    @available(*, deprecated: 5.0)
    public func always(on q: DispatchQueue = .main, execute body: @escaping () -> Void) -> Promise {
        return ensure(on: q, body)
    }
}

public extension Thenable {
    @available(*, deprecated: 6.1, message: "See: `compactMap`")
    func flatMap<U>(on: DispatchQueue? = conf.Q.map, _ transform: @escaping(T) throws -> U?) -> Promise<U> {
        return compactMap(on: on, transform)
    }
}

public extension Thenable where T: Sequence {
    @available(*, deprecated: 6.1, message: "See: `mapValues`")
    func map<U>(on: DispatchQueue? = conf.Q.map, _ transform: @escaping(T.Iterator.Element) throws -> U) -> Promise<[U]> {
        return mapValues(on: on, transform)
    }

    @available(*, deprecated: 6.1, message: "See: `flatMapValues`")
    func flatMap<U: Sequence>(on: DispatchQueue? = conf.Q.map, _ transform: @escaping(T.Iterator.Element) throws -> U) -> Promise<[U.Iterator.Element]> {
        return flatMapValues(on: on, transform)
    }

    @available(*, deprecated: 6.1, message: "See: `filterValues`")
    func filter(on: DispatchQueue? = conf.Q.map, test: @escaping (T.Iterator.Element) -> Bool) -> Promise<[T.Iterator.Element]> {
        return filterValues(on: on, test)
    }
}

public extension Thenable where T: Collection {
    @available(*, deprecated: 6.1, message: "See: `firstValue`")
    var first: Promise<T.Iterator.Element> {
        fatalError()
    }

    @available(*, deprecated: 6.1, message: "See: `lastValue`")
    var last: Promise<T.Iterator.Element> {
        return lastValue
    }
}

public extension Thenable where T: Sequence, T.Iterator.Element: Comparable {
    @available(*, deprecated: 6.1, message: "See: `sortedValues`")
    func sorted(on: DispatchQueue? = conf.Q.map) -> Promise<[T.Iterator.Element]> {
        return sortedValues(on: on)
    }
}
