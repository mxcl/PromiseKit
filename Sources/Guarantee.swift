import class Foundation.Thread
import Dispatch

/// A `Guarantee` is a functional abstraction around an asynchronous operation that cannot error.
public class Guarantee<T>: Thenable {
    let box: Box<T>

    fileprivate init(box: SealedBox<T>) {
        self.box = box
    }

    public static func value(_ value: T) -> Guarantee<T> {
        return .init(box: SealedBox(value: value))
    }

    public init(resolver body: (@escaping(T) -> Void) -> Void) {
        box = EmptyBox()
        body(box.seal)
    }

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

    public var result: Result<T>? {
        switch box.inspect() {
        case .pending:
            return nil
        case .resolved(let value):
            return .fulfilled(value)
        }
    }

    init(_: PMKUnambiguousInitializer) {
        box = EmptyBox()
    }

    public class func pending() -> (guarantee: Guarantee<T>, resolve: (T) -> Void) {
        return { ($0, $0.box.seal) }(Guarantee<T>(.pending))
    }
}

public extension Guarantee {
    @discardableResult
    func done(on: DispatchQueue? = conf.Q.return, _ body: @escaping(T) -> Void) -> Guarantee<Void> {
        let rg = Guarantee<Void>(.pending)
        pipe { (value: T) in
            on.async {
                body(value)
                rg.box.seal(())
            }
        }
        return rg
    }

    func map<U>(on: DispatchQueue? = conf.Q.map, _ body: @escaping(T) -> U) -> Guarantee<U> {
        let rg = Guarantee<U>(.pending)
        pipe { value in
            on.async {
                rg.box.seal(body(value))
            }
        }
        return rg
    }

	@discardableResult
    func then<U>(on: DispatchQueue? = conf.Q.map, _ body: @escaping(T) -> Guarantee<U>) -> Guarantee<U> {
        let rg = Guarantee<U>(.pending)
        pipe { value in
            on.async {
                body(value).pipe(to: rg.box.seal)
            }
        }
        return rg
    }

    public func asVoid() -> Guarantee<Void> {
        return map(on: nil) { _ in }
    }
    
    /**
     Blocks this thread, so you know, don’t call this on a serial thread that
     any part of your chain may use. Like the main thread for example.
     */
    public func wait() -> T {

        if Thread.isMainThread {
            print("PromiseKit: warning: `wait()` called on main thread!")
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

#if swift(>=3.1)
public extension Guarantee where T == Void {
    convenience init() {
        self.init(box: SealedBox(value: Void()))
    }
}
#endif


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


#if os(Linux)
import func CoreFoundation._CFIsMainThread

extension Thread {
    // `isMainThread` is not implemented yet in swift-corelibs-foundation.
    static var isMainThread: Bool {
        return _CFIsMainThread()
    }
}
#endif
