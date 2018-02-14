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
