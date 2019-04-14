import class Foundation.Thread
import Dispatch

/**
 A `Promise` is a functional abstraction around a failable asynchronous operation.
 - See: `Thenable`
 */
public final class Promise<T>: Thenable, CatchMixin, HasDispatchState {
    
    let box: Box<Result<T, Error>>
    var dispatchState: DispatchState = DispatchState()

    fileprivate init(box: SealedBox<Result<T, Error>>) {
        self.box = box
    }

    /**
      Initialize a new fulfilled promise.

      We do not provide `init(value:)` because Swift is “greedy”
      and would pick that initializer in cases where it should pick
      one of the other more specific options leading to Promises with
      `T` that is eg: `Error` or worse `(T->Void,Error->Void)` for
      uses of our PMK < 4 pending initializer due to Swift trailing
      closure syntax (nothing good comes without pain!).

      Though often easy to detect, sometimes these issues would be
      hidden by other type inference leading to some nasty bugs in
      production.

      In PMK5 we tried to work around this by making the pending
      initializer take the form `Promise(.pending)` but this led to
      bad migration errors for PMK4 users. Hence instead we quickly
      released PMK6 and now only provide this initializer for making
      sealed & fulfilled promises.

      Usage is still (usually) good:

          guard foo else {
              return .value(bar)
          }
     */
    public class func value(_ value: T) -> Promise<T> {
        return Promise(box: SealedBox(value: .success(value)))
    }

    /// Initialize a new rejected promise.
    public init(error: Error) {
        box = SealedBox(value: .failure(error))
    }

    /// Initialize a new promise bound to the provided `Thenable`.
    public init<U: Thenable>(_ bridge: U) where U.T == T {
        box = EmptyBox()
        bridge.pipe(to: box.seal)
    }

    /// Initialize a new promise that can be resolved with the provided `Resolver`.
    public init(resolver body: (Resolver<T>) throws -> Void) {
        box = EmptyBox()
        let resolver = Resolver(box)
        do {
            try body(resolver)
        } catch {
            resolver.reject(error)
        }
    }

    /// Initialize a new promise that can be resolved with the provided `Resolver`.
    public init(cancellable: Cancellable, resolver body: (Resolver<T>) throws -> Void) {
        box = EmptyBox()
        let resolver = Resolver(box)
        self.cancellable = cancellable
        self.rejectIfCancelled = resolver.reject
        do {
            try body(resolver)
        } catch {
            resolver.reject(error)
        }
    }

    /// - Returns: a tuple of a new pending promise and its `Resolver`.
    public class func pending() -> (promise: Promise<T>, resolver: Resolver<T>) {
        return { ($0, Resolver($0.box)) }(Promise<T>(.pending))
    }

    /// - See: `Thenable.pipe`
    public func pipe(to: @escaping(Result<T, Error>) -> Void) {
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
        case .resolved(let result):
            return result
        }
    }

    init(_: PMKUnambiguousInitializer) {
        box = EmptyBox()
    }
    
    var cancellable: Cancellable?
    var rejectIfCancelled: ((Error) -> Void)?
    
    public func setCancellable(_ cancellable: Cancellable?, reject: ((Error) -> Void)? = nil) {
        self.cancellable = cancellable
        rejectIfCancelled = reject
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
    
    public func dispatch(on: Dispatcher) -> Promise<T> {
        let (promise, seal) = Promise<T>.pending()
        promise.dispatchState = dispatchState.dispatch(on: on)
        pipe(to: seal.resolve)
        return promise
    }
}

public extension Promise {
    /**
     Blocks this thread, so—you know—don’t call this on a serial thread that
     any part of your chain may use. Like the main thread for example.
     */
    func wait() throws -> T {

        if Thread.isMainThread {
            conf.logHandler(.waitOnMainThread)
        }

        var result = self.result

        if result == nil {
            let group = DispatchGroup()
            group.enter()
            pipe { result = $0; group.leave() }
            group.wait()
        }

        return try result!.get()
    }
}

extension Promise where T == Void {
    /// Initializes a new promise fulfilled with `Void`
    public convenience init() {
        self.init(box: SealedBox(value: .success(Void())))
    }
}

public extension DispatchQueue {
    /**
     Asynchronously executes the provided closure on a dispatch queue, yielding a `Promise`.

         DispatchQueue.global().async(.promise) {
             try md5(input)
         }.done { md5 in
             //…
         }

     - Parameters:
       - _: Must be `.promise` to distinguish from standard `DispatchQueue.async`
       - group: A `DispatchGroup`, as for standard `DispatchQueue.async`
       - qos: A quality-of-service grade, as for standard `DispatchQueue.async`
       - flags: Work item flags, as for standard `DispatchQueue.async`
       - body: A closure that yields a value to resolve the promise.
     - Returns: A new `Promise` resolved by the result of the provided closure.
     */
    @available(macOS 10.10, iOS 8.0, tvOS 9.0, watchOS 2.0, *)
    final func async<T>(_: PMKNamespacer, group: DispatchGroup? = nil, qos: DispatchQoS? = nil, flags: DispatchWorkItemFlags? = nil, execute body: @escaping () throws -> T) -> Promise<T> {
        let promise = Promise<T>(.pending)
        asyncD(group: group, qos: qos, flags: flags) {
            do {
                promise.box.seal(.success(try body()))
            } catch {
                promise.box.seal(.failure(error))
            }
        }
        return promise
    }
}

public extension Dispatcher {
    /**
     Executes the provided closure on a `Dispatcher`, yielding a `Promise`
     that represents the value ultimately returned by the closure.
     
         dispatcher.dispatch {
            try md5(input)
         }.done { md5 in
            //…
         }
     
     - Parameter body: A closure that yields a value to resolve the promise.
     - Returns: A new `Promise` resolved by the result of the provided closure.
     */
    func dispatch<T>(_ body: @escaping () throws -> T) -> Promise<T> {
        let promise = Promise<T>(.pending)
        dispatch {
            do {
                promise.box.seal(.success(try body()))
            } catch {
                promise.box.seal(.failure(error))
            }
        }
        return promise
    }
}

/// used by our extensions to provide unambiguous functions with the same name as the original function
public enum PMKNamespacer {
    case promise
}

enum PMKUnambiguousInitializer {
    case pending
}
