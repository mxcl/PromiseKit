import class Foundation.Thread
import Dispatch

/**
 A `Guarantee` is a functional abstraction around an asynchronous operation that cannot error.
 - See: `Thenable`
*/
public final class Guarantee<T>: Thenable {
    let box: PromiseKit.Box<T>

    fileprivate init(box: SealedBox<T>) {
        self.box = box
    }

    /// Returns a `Guarantee` sealed with the provided value.
    public static func value(_ value: T) -> Guarantee<T> {
        return .init(box: SealedBox(value: value))
    }

    /// Returns a pending `Guarantee` that can be resolved with the provided closure’s parameter.
    public init(resolver body: (@escaping(T) -> Void) -> Void) {
        box = Box()
        body(box.seal)
    }

    /// - See: `Thenable.pipe`
    public func pipe(to: @escaping(Result<T>) -> Void) {
        pipe{ to(.fulfilled($0)) }
    }

    func pipe(to: @escaping(T) -> Void) {
        switch box.inspect() {
        case .pending:
            box.inspect {
                switch $0 {
                case .pending(let handlers):
                    handlers.append(to)
                case .resolved(let value):
                    to(value)
                }
            }
        case .resolved(let value):
            to(value)
        }
    }

    /// - See: `Thenable.result`
    public var result: Result<T>? {
        switch box.inspect() {
        case .pending:
            return nil
        case .resolved(let value):
            return .fulfilled(value)
        }
    }

    final private class Box<T>: EmptyBox<T> {
        deinit {
            switch inspect() {
            case .pending:
                PromiseKit.conf.logHandler(.pendingGuaranteeDeallocated)
            case .resolved:
                break
            }
        }
    }

    init(_: PMKUnambiguousInitializer) {
        box = Box()
    }

    /// Returns a tuple of a pending `Guarantee` and a function that resolves it.
    public class func pending() -> (guarantee: Guarantee<T>, resolve: (T) -> Void) {
        return { ($0, $0.box.seal) }(Guarantee<T>(.pending))
    }
}

public extension Guarantee {
    @discardableResult
    func done(on: Dispatcher = conf.D.return, _ body: @escaping(T) -> Void) -> Guarantee<Void> {
        let rg = Guarantee<Void>(.pending)
        pipe { (value: T) in
            on.dispatch {
                body(value)
                rg.box.seal(())
            }
        }
        return rg
    }
    
    func get(on: Dispatcher = conf.D.return, _ body: @escaping (T) -> Void) -> Guarantee<T> {
        return map(on: on) {
            body($0)
            return $0
        }
    }

    func map<U>(on: Dispatcher = conf.D.map, _ body: @escaping(T) -> U) -> Guarantee<U> {
        let rg = Guarantee<U>(.pending)
        pipe { value in
            on.dispatch {
                rg.box.seal(body(value))
            }
        }
        return rg
    }

	@discardableResult
    func then<U>(on: Dispatcher = conf.D.map, _ body: @escaping(T) -> Guarantee<U>) -> Guarantee<U> {
        let rg = Guarantee<U>(.pending)
        pipe { value in
            on.dispatch {
                body(value).pipe(to: rg.box.seal)
            }
        }
        return rg
    }

    func asVoid() -> Guarantee<Void> {
        return map(on: nil) { _ in }
    }
    
    /**
     Blocks this thread, so you know, don’t call this on a serial thread that
     any part of your chain may use. Like the main thread for example.
     */
    func wait() -> T {

        if Thread.isMainThread {
            conf.logHandler(.waitOnMainThread)
        }

        var result = value

        if result == nil {
            let group = DispatchGroup()
            group.enter()
            pipe { (foo: T) in result = foo; group.leave() }
            group.wait()
        }
        
        return result!
    }
}

public extension Guarantee where T: Sequence {

    /**
     `Guarantee<[T]>` => `T` -> `Guarantee<U>` => `Guarantee<[U]>`

         firstly {
             .value([1,2,3])
         }.thenMap {
             .value($0 * 2)
         }.done {
             // $0 => [2,4,6]
         }
     */
    func thenMap<U>(on: Dispatcher = conf.D.map, _ transform: @escaping(T.Iterator.Element) -> Guarantee<U>) -> Guarantee<[U]> {
        return then(on: on) {
            when(fulfilled: $0.map(transform))
        }.recover {
            // if happens then is bug inside PromiseKit
            fatalError(String(describing: $0))
        }
    }
}

public extension Guarantee where T == Void {
    convenience init() {
        self.init(box: SealedBox(value: Void()))
    }

#if swift(>=5.1)
    // ^^ ambiguous in Swift 5.0, testing again in next version
    convenience init(resolver body: (@escaping() -> Void) -> Void) {
        self.init(resolver: { seal in
            body {
                seal(())
            }
        })
    }
#endif
}

public extension DispatchQueue {
    /**
     Asynchronously executes the provided closure on a dispatch queue.

         DispatchQueue.global().async(.promise) {
             md5(input)
         }.done { md5 in
             //…
         }

     - Parameter body: The closure that resolves this promise.
     - Returns: A new `Guarantee` resolved by the result of the provided closure.
     - Note: There is no Promise/Thenable version of this due to Swift compiler ambiguity issues.
     */
    @available(macOS 10.10, iOS 2.0, tvOS 10.0, watchOS 2.0, *)
    final func async<T>(_: PMKNamespacer, group: DispatchGroup? = nil, qos: DispatchQoS = .default, flags: DispatchWorkItemFlags = [], execute body: @escaping () -> T) -> Guarantee<T> {
        let rg = Guarantee<T>(.pending)
        async(group: group, qos: qos, flags: flags) {
            rg.box.seal(body())
        }
        return rg
    }
}

public extension Dispatcher {
    /**
     Asynchronously executes the provided closure on a Dispatcher.
     
         dispatcher.guarantee {
            md5(input)
         }.done { md5 in
            //…
         }
     
     - Parameter body: The closure that resolves this promise.
     - Returns: A new `Guarantee` resolved by the result of the provided closure.
     - Note: There is no Promise/Thenable version of this due to Swift compiler ambiguity issues.
     */
    func dispatch<T>(_: PMKNamespacer, _ body: @escaping () -> T) -> Guarantee<T> {
        let rg = Guarantee<T>(.pending)
        dispatch {
            rg.box.seal(body())
        }
        return rg
    }
}

#if os(Linux)
import func CoreFoundation._CFIsMainThread

extension Thread {
    // `isMainThread` is not implemented yet in swift-corelibs-foundation.
    static var isMainThread: Bool {
        return _CFIsMainThread()
    }
}
#endif
