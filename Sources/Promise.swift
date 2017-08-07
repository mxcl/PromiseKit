import class Foundation.Thread
import Dispatch

public class Promise<T>: Thenable, CatchMixin {
    let box: Box<Result<T>>

    public init(value: T) {
        box = SealedBox(value: .fulfilled(value))
    }

    public init(error: Error) {
        box = SealedBox(value: .rejected(error))
    }

    public init<U: Thenable>(_ bridge: U) where U.T == T {
        box = EmptyBox()
        bridge.pipe(to: box.seal)
    }

    public init(_: PMKUnambiguousInitializer, resolver body: (Resolver<T>) throws -> Void) {
        box = EmptyBox()
        do {
            try body(Resolver(box))
        } catch {
            box.seal(.rejected(error))
        }
    }

    public class func pending() -> (promise: Promise<T>, resolver: Resolver<T>) {
        return { ($0, Resolver($0.box)) }(Promise<T>(.pending))
    }

    public func pipe(to: @escaping(Result<T>) -> Void) {
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
        case .resolved(let result):
            return result
        }
    }

    init(_: PMKUnambiguousInitializer) {
        box = EmptyBox()
    }
}

public extension Promise {
    func tap(_ body: @escaping(Result<T>) -> Void) -> Promise {
        pipe(to: body)
        return self
    }

    public func asVoid() -> Promise<Void> {
        return map(on: nil) { _ in }
    }
    
    /**
     Blocks this thread, so you know, don’t call this on a serial thread that
     any part of your chain may use. Like the main thread for example.
     */
    public func wait() throws -> T {

        if Thread.isMainThread {
            print("PromiseKit: warning: `wait()` called on main thread!")
        }

        var result = self.result

        if result == nil {
            let group = DispatchGroup()
            group.enter()
            pipe { result = $0; group.leave() }
            group.wait()
        }

        switch result! {
        case .rejected(let error):
            throw error
        case .fulfilled(let value):
            return value
        }
    }
}

#if swift(>=3.1)
extension Promise where T == Void {
    public convenience init() {
        self.init(value: Void())
    }
}
#endif


public extension DispatchQueue {
    /**
     Asynchronously executes the provided closure on a dispatch queue.

         DispatchQueue.global().async(.promise) {
             try md5(input)
         }.done { md5 in
             //…
         }

     - Parameter body: The closure that resolves this promise.
     - Returns: A new `Promise` resolved by the result of the provided closure.
     - Note: There is no Promise/Thenable version of this due to Swift compiler ambiguity issues.
     */
    final func async<T>(_: PMKNamespacer, group: DispatchGroup? = nil, qos: DispatchQoS = .default, flags: DispatchWorkItemFlags = [], execute body: @escaping () throws -> T) -> Promise<T> {
        let promise = Promise<T>(.pending)
        async(group: group, qos: qos, flags: flags) {
            do {
                promise.box.seal(.fulfilled(try body()))
            } catch {
                promise.box.seal(.rejected(error))
            }
        }
        return promise
    }
}


/// used by our extensions to provide unambiguous functions with the same name as the original function
public enum PMKNamespacer {
    case promise
}

public enum PMKUnambiguousInitializer {
    case pending
}
