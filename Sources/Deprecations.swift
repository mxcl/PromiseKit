import Dispatch

@available(*, deprecated, message: "See `init(resolver:)`")
public func wrap<T>(_ body: (@escaping (T?, Error?) -> Void) throws -> Void) -> Promise<T> {
    return Promise { seal in
        try body(seal.resolve)
    }
}

@available(*, deprecated, message: "See `init(resolver:)`")
public func wrap<T>(_ body: (@escaping (T, Error?) -> Void) throws -> Void) -> Promise<T>  {
    return Promise { seal in
        try body(seal.resolve)
    }
}

@available(*, deprecated, message: "See `init(resolver:)`")
public func wrap<T>(_ body: (@escaping (Error?, T?) -> Void) throws -> Void) -> Promise<T> {
    return Promise { seal in
        try body(seal.resolve)
    }
}

@available(*, deprecated, message: "See `init(resolver:)`")
public func wrap(_ body: (@escaping (Error?) -> Void) throws -> Void) -> Promise<Void> {
    return Promise { seal in
        try body(seal.resolve)
    }
}

@available(*, deprecated, message: "See `init(resolver:)`")
public func wrap<T>(_ body: (@escaping (T) -> Void) throws -> Void) -> Promise<T> {
    return Promise { seal in
        try body(seal.fulfill)
    }
}

public extension Promise {
    @available(*, deprecated, message: "See `ensure`")
    public func always(on q: DispatchQueue = .main, execute body: @escaping () -> Void) -> Promise {
        return ensure(on: q, body)
    }
}

public extension Thenable {
#if PMKFullDeprecations
    /// disabled due to ambiguity with the other `.flatMap`
    @available(*, deprecated: 6.1, message: "See: `compactMap`")
    func flatMap<U>(on: DispatchQueue? = conf.Q.map, _ transform: @escaping(T) throws -> U?) -> Promise<U> {
        return compactMap(on: on, transform)
    }
#endif
}

public extension Thenable where T: Sequence {
#if PMKFullDeprecations
    /// disabled due to ambiguity with the other `.map`
    @available(*, deprecated, message: "See: `mapValues`")
    func map<U>(on: DispatchQueue? = conf.Q.map, _ transform: @escaping(T.Iterator.Element) throws -> U) -> Promise<[U]> {
        return mapValues(on: on, transform)
    }

    /// disabled due to ambiguity with the other `.flatMap`
    @available(*, deprecated, message: "See: `flatMapValues`")
    func flatMap<U: Sequence>(on: DispatchQueue? = conf.Q.map, _ transform: @escaping(T.Iterator.Element) throws -> U) -> Promise<[U.Iterator.Element]> {
        return flatMapValues(on: on, transform)
    }
#endif

    @available(*, deprecated, message: "See: `filterValues`")
    func filter(on: DispatchQueue? = conf.Q.map, test: @escaping (T.Iterator.Element) -> Bool) -> Promise<[T.Iterator.Element]> {
        return filterValues(on: on, test)
    }
}

public extension Thenable where T: Collection {
    @available(*, deprecated, message: "See: `firstValue`")
    var first: Promise<T.Iterator.Element> {
        return firstValue
    }

    @available(*, deprecated, message: "See: `lastValue`")
    var last: Promise<T.Iterator.Element> {
        return lastValue
    }
}

public extension Thenable where T: Sequence, T.Iterator.Element: Comparable {
    @available(*, deprecated, message: "See: `sortedValues`")
    func sorted(on: DispatchQueue? = conf.Q.map) -> Promise<[T.Iterator.Element]> {
        return sortedValues(on: on)
    }
}
