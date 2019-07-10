import class Foundation.Thread
import Dispatch

/**
 A `Guarantee` is a functional abstraction around an asynchronous operation that cannot error.
 - See: `Thenable`
*/
public final class Guarantee<T>: Thenable, HasDispatchState {
    
    let box: PromiseKit.Box<T>
    var dispatchState: DispatchState = DispatchState()

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

    /// Returns a pending `Guarantee` that can be resolved with the provided closure’s parameter.
    public convenience init(cancellable: Cancellable, resolver body: (@escaping(T) -> Void) -> Void) {
        self.init(resolver: body)
       setCancellable(cancellable)
    }
    
    /// - See: `Thenable.pipe`
    public func pipe(to: @escaping(Result<T, Error>) -> Void) {
        pipe{ to(.success($0)) }
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
    public var result: Result<T, Error>? {
        switch box.inspect() {
        case .pending:
            return nil
        case .resolved(let value):
            return .success(value)
        }
    }

    final private class Box<T>: EmptyBox<T> {
        var cancelled = false
        deinit {
            switch inspect() {
            case .pending:
                if !cancelled {
                    PromiseKit.conf.logHandler(.pendingGuaranteeDeallocated)
                }
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
    
    var cancellable: Cancellable?
    
    public func setCancellable(_ cancellable: Cancellable) {
        if let gb = (box as? Guarantee<T>.Box<T>) {
            self.cancellable = CancellableWrapper(box: gb, cancellable: cancellable)
        } else {
            self.cancellable = cancellable
        }
    }

    final private class CancellableWrapper: Cancellable {
        let box: Guarantee<T>.Box<T>
        let cancellable: Cancellable

        init(box: Guarantee<T>.Box<T>, cancellable: Cancellable) {
            self.box = box
            self.cancellable = cancellable
        }

        func cancel() {
            box.cancelled = true
            cancellable.cancel()
        }

        var isCancelled: Bool {
            return cancellable.isCancelled
        }
    }
}

public extension Guarantee {
    @discardableResult
    func done(on: Dispatcher = conf.dd, _ body: @escaping(T) -> Void) -> Guarantee<Void> {
        let rg = Guarantee<Void>(.pending)
        rg.dispatchState = dispatchState.nextState(givenDispatcher: on, isTailFunction: true)
        pipe { (value: T) in
            rg.dispatch {
                body(value)
                rg.box.seal(())
            }
        }
        return rg
    }
    
    func get(on: Dispatcher = conf.dd, _ body: @escaping (T) -> Void) -> Guarantee<T> {
        return map(on: on) {
            body($0)
            return $0
        }
    }

    func map<U>(on: Dispatcher = conf.dd, _ body: @escaping(T) -> U) -> Guarantee<U> {
        let rg = Guarantee<U>(.pending)
        rg.dispatchState = dispatchState.nextState(givenDispatcher: on)
        pipe { value in
            rg.dispatch {
                rg.box.seal(body(value))
            }
        }
        return rg
    }

	@discardableResult
    func then<U>(on: Dispatcher = conf.dd, _ body: @escaping(T) -> Guarantee<U>) -> Guarantee<U> {
        let rg = Guarantee<U>(.pending)
        rg.dispatchState = dispatchState.nextState(givenDispatcher: on)
        pipe { value in
            rg.dispatch {
                body(value).pipe(to: rg.box.seal)
            }
        }
        return rg
    }

    /// Set a default Dispatcher for the chain. Within the chain, this Dispatcher will remain the
    /// default until you change it, even if you dispatch individual closures to other Dispatchers.
    ///
    /// - Note: If you set a chain dispatcher within the body of a promise chain, you must
    ///   "confirm" the chain dispatcher when it gets to the tail to avoid a warning from
    ///   PromiseKit. To do this, just include `on: .chain` as an argument to the chain's
    ///   first `done`, `catch`, or `finally`.
    ///
    /// - Parameters:
    ///   - on: The new default Dispatcher. Use `.default` to return to normal dispatching.
    
    func dispatch(on: Dispatcher) -> Guarantee<T> {
        let (guarantee, seal) = Guarantee<T>.pending()
        guarantee.dispatchState = dispatchState.dispatch(on: on)
        pipe(to: seal)
        return guarantee
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
    func thenMap<U>(on: Dispatcher = conf.dd, _ transform: @escaping(T.Iterator.Element) -> Guarantee<U>) -> Guarantee<[U]> {
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
     Asynchronously executes the provided closure on a dispatch queue, yielding a `Guarantee`.

         DispatchQueue.global().async(.promise) {
             md5(input)
         }.done { md5 in
             //…
         }

     - _: Must be `.promise` to distinguish from standard `DispatchQueue.async`
     - group: A `DispatchGroup`, as for standard `DispatchQueue.async`
     - qos: A quality-of-service grade, as for standard `DispatchQueue.async`
     - flags: Work item flags, as for standard `DispatchQueue.async`
     - body: A closure that yields a value to resolve the guarantee.
     - Returns: A new `Guarantee` resolved by the result of the provided closure.
     */
    @available(macOS 10.10, iOS 2.0, tvOS 10.0, watchOS 2.0, *)
    final func async<T>(_: PMKNamespacer, group: DispatchGroup? = nil, qos: DispatchQoS? = nil, flags: DispatchWorkItemFlags? = nil, execute body: @escaping () -> T) -> Guarantee<T> {
        let rg = Guarantee<T>(.pending)
        asyncD(group: group, qos: qos, flags: flags) {
            rg.box.seal(body())
        }
        return rg
    }
}

public extension Dispatcher {
    /**
     Executes the provided closure on a `Dispatcher`, yielding a `Guarantee`
     that represents the value ultimately returned by the closure.

         dispatcher.dispatch {
            md5(input)
         }.done { md5 in
            //…
         }
     
     - Parameter body: The closure that yields the value of the Guarantee.
     - Returns: A new `Guarantee` resolved by the result of the provided closure.
     */
    func dispatch<T>(_ body: @escaping () -> T) -> Guarantee<T> {
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
