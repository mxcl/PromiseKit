import Foundation


// Caveats (specify fixes alongside)
// * Promise { throw E.dummy } is interpreted as `Promise<() throws -> Void>` of all things
// * Promise(E.dummy) is interpreted as `Promise<E>`


// Remarks:
// * We typically use `.pending()` to reduce nested insanities in your backtraces


public protocol Thenable: class {
    associatedtype T
    func pipe(to: @escaping (Result<T>) -> Void)
    var result: Result<T>? { get }
}

public protocol Catchable: Thenable
{}

private enum Schrödinger<R> {
    case pending(Handlers<R>)
    case resolved(R)
}

public enum Result<T> {
    case rejected(Error)
    case fulfilled(T)
}

private class Handlers<R> {
    var bodies: [(R) -> Void] = []
}

public enum UnambiguousInitializer {
    case start
}

private protocol Mixin: class {
    associatedtype R
    var barrier: DispatchQueue { get }
    var _schrödinger: Schrödinger<R> { get set }
    var schrödinger: Schrödinger<R> { get set }
}

extension Mixin {
    var schrödinger: Schrödinger<R> {
        get {
            var result: Schrödinger<R>!
            barrier.sync {
                result = _schrödinger
            }
            return result
        }
        set {
            guard case .resolved(let result) = newValue else {
                fatalError()
            }
            var bodies: [(R) -> Void]!
            barrier.sync(flags: .barrier) {
                guard case .pending(let handlers) = self._schrödinger else {
                    return  // already fulfilled!
                }
                bodies = handlers.bodies
                self._schrödinger = newValue
            }

            //FIXME we are resolved so should `pipe(to:)` be called at this instant, “thens are called in order” would be invalid
            //NOTE we don’t do this in the above `sync` because that could potentially deadlock
            //THOUGH since `then` etc. typically invoke after a run-loop cycle, this issue is somewhat less severe

            if let bodies = bodies {
                for body in bodies {
                    body(result)
                }
            }
        }
    }
    public func pipe(to body: @escaping (R) -> Void) {
        var result: R?
        barrier.sync {
            switch _schrödinger {
            case .pending:
                break
            case .resolved(let resolute):
                result = resolute
            }
        }
        if result == nil {
            barrier.sync(flags: .barrier) {
                switch _schrödinger {
                case .pending(let handlers):
                    handlers.bodies.append(body)
                case .resolved(let resolute):
                    result = resolute
                }
            }
        }
        if let result = result {
            body(result)
        }
    }
}

private enum PendingIntializer {
    case pending
}


/**
 A *promise* represents the future Wrapped of a (usually) asynchronous task.

 To obtain the Wrapped of a promise we call `then`.

 Promises are chainable: `then` returns a promise, you can call `then` on
 that promise, which returns a promise, you can call `then` on that
 promise, et cetera.

 Promises start in a pending state and *resolve* with a Wrapped to become
 *fulfilled* or an `Error` to become rejected.

 - SeeAlso: [PromiseKit 101](http://promisekit.org/docs/)
 */
public final class Promise<T>: Thenable, Catchable, Mixin {

    @inline(__always)
    fileprivate convenience init(_: PendingIntializer) {
        self.init(schrödinger: .pending(Handlers()))
    }

    @inline(__always)
    fileprivate init(schrödinger cat: Schrödinger<Result<T>>) {
        barrier = DispatchQueue(label: "org.promisekit.barrier", attributes: .concurrent)
        _schrödinger = cat
    }

    public convenience init(seal body: (Sealant<T>) throws -> Void) {
        do {
            self.init(.pending)
            let sealant = Sealant{ self.schrödinger = .resolved($0) }
            try body(sealant)
        } catch {
            _schrödinger = .resolved(.rejected(error))
        }
    }

    public init(_: UnambiguousInitializer, assimilate body: () throws -> Promise) {
        do {
            let host = try body()
            barrier = host.barrier             //FIXME not thread-safe
            _schrödinger = host._schrödinger   //FIXME not thread-safe
        } catch {
            barrier = DispatchQueue(label: "org.promisekit.barrier", attributes: .concurrent)
            _schrödinger = .resolved(.rejected(error))
        }
    }

    /// - Note: `Promise()` thus creates a *fulfilled* `Void` promise.
    /// - TODO: Ideally this would not exist, since it is better to make a `Guarantee`.
    /// - Remark: It is possible to create a `Promise<Error>` with this method. Generally this isn’t what you really want and trying to use it will quickly reveal that and then you'll realize your mistake.
    public convenience init(_ value: T) {
        self.init(schrödinger: .resolved(.fulfilled(value)))
    }

    public convenience init(error: Error) {
        self.init(schrödinger: .resolved(.rejected(error)))
    }

    //TODO optimization: don't need these if instantiated sealed
    fileprivate let barrier: DispatchQueue
    fileprivate var _schrödinger: Schrödinger<Result<T>>

    public var result: Result<T>? {
        switch schrödinger {
        case .pending:
            return nil
        case .resolved(let result):
            return result
        }
    }

    public static func pending() -> (promise: Promise, seal: Sealant<T>) {
        let promise = Promise(.pending)
        let sealant = Sealant{ promise.schrödinger = .resolved($0) }
        return (promise, sealant)
    }

    public func asVoid() -> Promise<Void> {
        return then{ _ in }
    }
}


extension Thenable {
    public func then<U: Thenable>(on: ExecutionContext = NextMainRunloopContext(), execute body: @escaping (T) throws -> U) -> Promise<U.T> {
        let promise = Promise<U.T>(.pending)
        pipe { result in
            switch result {
            case .fulfilled(let value):
                on.pmkAsync {
                    do {
                        let intermediary = try body(value)
                        guard intermediary !== promise else { throw PMKError.returnedSelf }
                        intermediary.pipe{ promise.schrödinger = .resolved($0) }
                    } catch {
                        promise.schrödinger = .resolved(.rejected(error))
                    }
                }
            case .rejected(let error):
                promise.schrödinger = .resolved(.rejected(error))
            }
        }
        return promise
    }

    public func then<U>(on: ExecutionContext = NextMainRunloopContext(), execute body: @escaping (T) throws -> U) -> Promise<U> {
        let promise = Promise<U>(.pending)
        pipe { result in
            switch result {
            case .fulfilled(let value):
                on.pmkAsync {
                    let result: Result<U>
                    do {
                        let value = try body(value)
                        result = .fulfilled(value)
                    } catch {
                        result = .rejected(error)
                    }
                    promise.schrödinger = .resolved(result)
                }
            case .rejected(let error):
                promise.schrödinger = .resolved(.rejected(error))
            }
        }
        return promise
    }
}

extension Catchable {
    public func ensure(on: ExecutionContext = NextMainRunloopContext(), that body: @escaping () -> Void) -> Self {
        pipe { _ in
            on.pmkAsync(execute: body)
        }
        return self
    }

    @discardableResult
    public func `catch`(on: ExecutionContext = NextMainRunloopContext(), handler body: @escaping (Error) -> Void) -> Finally {
        let finally = Finally()
        pipe { result in
            switch result {
            case .fulfilled:
                break
            case .rejected(let error):
                on.pmkAsync {
                    body(error)
                }
            }
            finally.schrödinger = .resolved()
        }
        return finally
    }

    public var error: Error? {
        switch result {
        case .rejected(let error)?:
            return error
        case .fulfilled?, nil:
            return nil
        }
    }

    public func recover(on: ExecutionContext = NextMainRunloopContext(), transform body: @escaping (Error) throws -> T) -> Promise<T> {
        let promise = Promise<T>(.pending)
        pipe { result in
            switch result {
            case .rejected(let error):
                on.pmkAsync {
                    do {
                        promise.schrödinger = .resolved(.fulfilled(try body(error)))
                    } catch {
                        promise.schrödinger = .resolved(.rejected(error))
                    }
                }
            case .fulfilled:
                promise.schrödinger = .resolved(result)
            }
        }
        return promise
    }

    /// - Remark: Removes errors, thus returns `Guarantee`
    public func recover(on: ExecutionContext = NextMainRunloopContext(), transform body: @escaping (Error) -> T) -> Guarantee<T> {
        let (guarantee, seal) = Guarantee<T>.pending()
        pipe { result in
            switch result {
            case .rejected(let error):
                on.pmkAsync {
                    seal(body(error))
                }
            case .fulfilled(let value):
                seal(value)
            }
        }
        return guarantee
    }

    /**
      - Remark: Swift infers the other form for one-liners:

          foo().recover{ Promise() }  // => Promise<Promise<Void>>
        
        We don’t know how to stop it.
     */
    public func recover<U: Thenable>(on: ExecutionContext = NextMainRunloopContext(), transform body: @escaping (Error) throws -> U) -> Promise<T> where U.T == T {
        let promise = Promise<T>(.pending)
        pipe { result in
            switch result {
            case .rejected(let error):
                on.pmkAsync {
                    do {
                        let intermediary = try body(error)
                        guard intermediary !== promise else { throw PMKError.returnedSelf }
                        intermediary.pipe{ promise.schrödinger = .resolved($0) }
                    } catch {
                        promise.schrödinger = .resolved(.rejected(error))
                    }
                }
            case .fulfilled:
                promise.schrödinger = .resolved(result)
            }
        }
        return promise
    }
}

public final class Finally {  //TODO thread-safety!
    fileprivate var schrödinger: Schrödinger<Void> = .pending(Handlers()) {
        didSet {
            guard case .pending(let handlers) = oldValue else { fatalError() }
            for handler in handlers.bodies {
                handler()
            }
        }
    }

    @discardableResult
    public func finally(_ body: @escaping () -> Void) -> Finally {
        switch schrödinger {
        case .pending(let handlers):
            handlers.bodies.append(body)
        case .resolved:
            body()
        }
        return self
    }
}


#if !SWIFT_PACKGE

private func unwrap(_ any: Any?) -> Result<Any?> {
    if let error = any as? Error {
        return .rejected(error)
    } else {
        return .fulfilled(any)
    }
}

@objc(AnyPromise)
public final class AnyPromise: NSObject, Thenable, Catchable, Mixin {
    public var result: Result<Any?>? {
        switch schrödinger {
        case .resolved(let value):
            return unwrap(value)
        case .pending:
            return nil
        }
    }

    fileprivate let barrier = DispatchQueue(label: "org.promisekit.barrier", attributes: .concurrent)
    fileprivate var _schrödinger: Schrödinger<Any?>

    public func pipe(to body: @escaping (Result<Any?>) -> Void) {
        let body = { body(unwrap($0)) }
        pipe(to: body)
    }

    public override init() {
        _schrödinger = .resolved(nil)
        super.init()
    }

    private init(schrödinger: Schrödinger<T>) {
        _schrödinger = schrödinger
    }

    @objc static func promiseWithValue(_ value: Any?) -> AnyPromise {
        return AnyPromise(schrödinger: .resolved(value))
    }

    @objc static func promiseWithResolverBlock(_ body: @convention(block) (@escaping (Any?) -> Void) -> Void) -> AnyPromise {
        let promise = AnyPromise(schrödinger: .pending(Handlers()))
        body{ promise.schrödinger = .resolved($0) }
        return promise
    }

    @objc func pipeTo(_ body: @convention(block) @escaping (Any?) -> Void) {
        pipe(to: body)
    }

    @objc var value: Any? {
        switch schrödinger {
        case .resolved(let obj):
            return obj
        case .pending:
            return nil
        }
    }

    @objc var pending: Bool { return isPending }
    @objc var fulfilled: Bool { return isFulfilled }
    @objc var rejected: Bool { return isRejected }
    @objc var resolved: Bool { return isResolved }
}

#endif

/** - Remark: much like a real-life guarantee, it is only as reliable as the source; “promises”
 may never resolve, it is up to the thing providing you the promise to ensure that they do.
 Generally it is considered bad programming for a promise provider to provide a promise that
 never resolves. In real life a guarantee may not be met by eg. World War III, so think
 similarly.
 */
public final class Guarantee<T>: Thenable, Mixin {

    fileprivate let barrier = DispatchQueue(label: "org.promisekit.barrier", attributes: .concurrent)
    fileprivate var _schrödinger: Schrödinger<T>

    /// - Remark: `Guarantee()` thus creates a resolved `Void` Guarantee.
    public init(_ value: T) {
        _schrödinger = .resolved(value)
    }

    public init(sealant body: (@escaping (T) -> Void) -> Void) {
        _schrödinger = .pending(Handlers())
        body { self.schrödinger = .resolved($0) }
    }

    private init(schrödinger: Schrödinger<T>) {
        _schrödinger = schrödinger
    }

    public static func pending() -> (Guarantee<T>, (T) -> Void) {
        let g = Guarantee<T>(schrödinger: .pending(Handlers()))
        return (g, { g.schrödinger = .resolved($0) })
    }

    public func pipe(to body: @escaping (Result<T>) -> Void) {
        pipe(to: { body(.fulfilled($0)) })
    }

    public var result: Result<T>? {
        switch schrödinger {
        case .pending:
            return nil
        case .resolved(let value):
            return .fulfilled(value)
        }
    }

    @discardableResult
    public func then<U>(on: ExecutionContext = NextMainRunloopContext(), execute body: @escaping (T) -> Guarantee<U>) -> Guarantee<U> {
        let (guarantee, seal) = Guarantee<U>.pending()
        pipe { value in
            on.pmkAsync {
                body(value).pipe(to: seal)
            }
        }
        return guarantee
    }

    @discardableResult
    public func then<U>(on: ExecutionContext = NextMainRunloopContext(), execute body: @escaping (T) -> U) -> Guarantee<U> {
        let (guarantee, seal) = Guarantee<U>.pending()
        pipe { value in
            on.pmkAsync {
                seal(body(value))
            }
        }
        return guarantee
    }
}

private protocol _DispatchQoS {
    var the: DispatchQoS { get }
}
extension DispatchQoS: _DispatchQoS {
    var the: DispatchQoS { return self }
}

extension Optional where Wrapped: _DispatchQoS {
    @inline(__always)
    fileprivate func async(execute body: @escaping () -> Void) {
        switch self {
        case .none:
            body()
        case .some(let qos):
            DispatchQueue.global().async(group: nil, qos: qos.the, flags: [], execute: body)
        }
    }
}

extension Thenable {
    public func tap(execute body: @escaping (Result<T>) -> Void) -> Self {
        pipe(to: body)
        return self
    }

    public var value: T? {
        switch result {
        case .fulfilled(let value)?:
            return value
        case .rejected?, nil:
            return nil
        }
    }

    public var isFulfilled: Bool {
        switch result {
        case .fulfilled?:
            return true
        case .rejected?, nil:
            return false
        }
    }

    public var isRejected: Bool {
        switch result {
        case .rejected?:
            return true
        case .fulfilled?, nil:
            return false
        }
    }

    public var isPending: Bool {
        switch result {
        case .fulfilled?, .rejected?:
            return false
        case nil:
            return true
        }
    }

    public var isResolved: Bool {
        switch result {
        case .fulfilled?, .rejected?:
            return true
        case nil:
            return false
        }
    }
}



@inline(__always)
public func race<U: Thenable>(_ thenables: U...) -> Promise<U.T> {
    return race(thenables)
}

public func race<U: Thenable>(_ thenables: [U]) -> Promise<U.T> {
    let result = Promise<U.T>(.pending)
    for thenable in thenables {
        thenable.pipe{ result.schrödinger = .resolved($0) }
    }
    return result
}

@inline(__always)
public func race<T>(_ guarantees: Guarantee<T>...) -> Guarantee<T> {
    return race(guarantees)
}

public func race<T>(_ guarantees: [Guarantee<T>]) -> Guarantee<T> {
    let (result, seal) = Guarantee<T>.pending()
    for thenable in guarantees {
        thenable.pipe(to: seal)
    }
    return result
}



public func when<U, V>(fulfilled u: Promise<U>, _ v: Promise<V>) -> Promise<(U, V)> {
    return when(fulfilled: [u.asVoid(), v.asVoid()]).then{ _ in (u.value!, v.value!) }
}

public func when<U, V, X>(fulfilled u: Promise<U>, _ v: Promise<V>, _ x: Promise<X>) -> Promise<(U, V, X)> {
    return when(fulfilled: [u.asVoid(), v.asVoid(), x.asVoid()]).then{ _ in (u.value!, v.value!, x.value!) }
}

public func when<U, V, X, Y>(fulfilled u: Promise<U>, _ v: Promise<V>, _ x: Promise<X>, _ y: Promise<Y>) -> Promise<(U, V, X, Y)> {
    return when(fulfilled: [u.asVoid(), v.asVoid(), x.asVoid(), y.asVoid()]).then{ _ in (u.value!, v.value!, x.value!, y.value!) }
}

public func when<U, V, X, Y, Z>(fulfilled u: Promise<U>, _ v: Promise<V>, _ x: Promise<X>, _ y: Promise<Y>, _ z: Promise<Z>) -> Promise<(U, V, X, Y, Z)> {
    return when(fulfilled: [u.asVoid(), v.asVoid(), x.asVoid(), y.asVoid(), z.asVoid()]).then{ _ in (u.value!, v.value!, x.value!, y.value!, z.value!) }
}

/// - Remark: There is no `...` variant, because it is then confusing that you put a splat in and don't get a splat out, when compared with the typical usage for our above splatted kinds
public func when<U: Thenable>(fulfilled thenables: [U]) -> Promise<[U.T]> {
    let rv = Promise<[U.T]>(.pending)
    var values = Array<U.T!>(repeating: nil, count: thenables.count)
    var x = thenables.count

    for (index, thenable) in thenables.enumerated() {
        thenable.pipe { result in
            switch result {
            case .rejected(let error):
                rv.schrödinger = .resolved(.rejected(error))
            case .fulfilled(let value):
                values[index] = value
                x -= 1
                if x == 0 {
                    rv.schrödinger = .resolved(.fulfilled(values))
                }
            }
        }
    }

    return rv
}

@discardableResult
public func when<U>(fulfilled guarantees: [Guarantee<U>]) -> Guarantee<[U]> {
    let (rv, seal) = Guarantee<[U]>.pending()
    var values = Array<U!>(repeating: nil, count: guarantees.count)
    var x = guarantees.count

    for (index, guarantee) in guarantees.enumerated() {
        guarantee.pipe { (value: U) in
            values[index] = value
            x -= 1
            if x == 0 {
                seal(values)
            }
        }
    }

    return rv
}


extension Promise {
    func then<U, V>(execute body: @escaping (T) -> (Promise<U>, Promise<V>)) -> Promise<(U,V)> {
        let promise = Promise<(U, V)>(.pending)
        pipe { result in
            switch result {
            case .fulfilled(let value):
                let (u, v) = body(value)
                when(fulfilled: u, v).pipe{ promise.schrödinger = .resolved($0) }
            case .rejected(let error):
                promise.schrödinger = .resolved(.rejected(error))
            }
        }
        return promise
    }

    func then<U, V, X>(execute body: @escaping (T) -> (Promise<U>, Promise<V>, Promise<X>)) -> Promise<(U,V,X)> {
        let promise = Promise<(U, V, X)>(.pending)
        pipe { result in
            switch result {
            case .fulfilled(let value):
                let (u, v, x) = body(value)
                when(fulfilled: u, v, x).pipe{ promise.schrödinger = .resolved($0) }
            case .rejected(let error):
                promise.schrödinger = .resolved(.rejected(error))
            }
        }
        return promise
    }
}


public func when<U: Thenable>(resolved thenables: U...) -> Guarantee<[Result<U.T>]> {
    let (rv, seal) = Guarantee<[Result<U.T>]>.pending()
    var results = [Result<U.T>]()
    var x = thenables.count

    for (index, thenable) in thenables.enumerated() {
        thenable.pipe { result in
            results[index] = result
            x -= 1
            if x == 0 {
                seal(results)
            }
        }
    }

    return rv
}


extension Thenable where T: Collection {
    /**
     Transforms a `Promise` where `T` is a `Collection` into a `Promise<[U]>`
     
         func download(urls: [String]) -> Promise<UIImage> {
             //…
         }

         return URLSession.shared.dataTask(url: url).asArray().map(download)

     Equivalent to:

         func download(urls: [String]) -> Promise<UIImage> {
             //…
         }

         return URLSession.shared.dataTask(url: url).then { urls in
             return when(fulfilled: urls.map(download))
         }


     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter transform: The closure that executes when this promise resolves.
     - Returns: A new promise, resolved with this promise’s resolution.
     */
    public final func map<U>(transform: @escaping (T.Iterator.Element) throws -> Promise<U>) -> Promise<[U]>
    {
        return then{ when(fulfilled: try $0.map(transform)) }
    }

    /// `nil` is an error.
    public func flatMap<U>(on: ExecutionContext = NextMainRunloopContext(), _ transform: @escaping (T.Iterator.Element) -> U?) -> Promise<[U]> {
        return then(on: on) { values in
            return try values.map { value in
                guard let result = transform(value) else {
                    throw PMKError.flatMap(value, U.self)
                }
                return result
            }
        }
    }
}

extension Thenable {
    /**
     Transforms the value of this promise using the provided function.
 
     If the result is nil, rejects the returned promise with `PMKError.flatMap`.

     - Remark: Essentially, this is a more specific form of `then` which errors for `nil`.
     - Remark: This function is useful for parsing eg. JSON.
     */
    public func flatMap<U>(_ transform: @escaping (T) -> U?) -> Promise<U> {
        return then(on: zalgo) { value in
            guard let result = transform(value) else {
                throw PMKError.flatMap(value, U.self)
            }
            return result
        }
    }
}


extension DispatchQueue {
    public func promise<T>(group: DispatchGroup? = nil, qos: DispatchQoS = .default, flags: DispatchWorkItemFlags = [], execute body: @escaping () throws -> T) -> Promise<T> {
        let promise = Promise<T>(.pending)
        async(group: group, qos: qos, flags: flags) {
            do {
                promise.schrödinger = .resolved(.fulfilled(try body()))
            } catch {
                promise.schrödinger = .resolved(.rejected(error))
            }
        }
        return promise
    }

    public func promise<T>(group: DispatchGroup? = nil, qos: DispatchQoS = .default, flags: DispatchWorkItemFlags = [], execute body: @escaping () -> T) -> Guarantee<T> {
        let (promise, seal) = Guarantee<T>.pending()
        async(group: group, qos: qos, flags: flags) {
            seal(body())
        }
        return promise
    }
}
