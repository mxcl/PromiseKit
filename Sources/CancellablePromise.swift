import class Foundation.Thread
import Dispatch

/**
 A `CancellablePromise` is a functional abstraction around a failable and cancellable asynchronous operation.
 
 At runtime the promise can become a member of a chain of promises, where the `cancelContext` is used to track and cancel (if desired) all promises in this chain.
 
 - See: `CancellableThenable`
 */
public class CancellablePromise<T>: CancellableThenable, CancellableCatchMixin {
    /// Delegate `promise` for this CancellablePromise
    public let promise: Promise<T>
    
    /// Type of the delegate `thenable`
    public typealias U = Promise<T>
    
    /// Delegate `thenable` for this CancellablePromise
    public var thenable: U {
        return promise
    }

    /// Type of the delegate `catchable`
    public typealias C = Promise<T>
    
    /// Delegate `catchable` for this CancellablePromise
    public var catchable: C {
        return promise
    }
    
    /// The CancelContext associated with this CancellablePromise
    public var cancelContext: CancelContext
    
    /// Tracks the cancel items for this CancellablePromise.  These items are removed from the associated CancelContext when the promise resolves.
    public var cancelItemList: CancelItemList
    
    init(promise: Promise<T>, context: CancelContext? = nil, cancelItemList: CancelItemList? = nil) {
        self.promise = promise
        self.cancelContext = context ?? CancelContext()
        self.cancelItemList = cancelItemList ?? CancelItemList()
    }
    
    /// Initialize a new rejected cancellable promise.
    public convenience init(cancellable: Cancellable? = nil, error: Error) {
        var reject: ((Error) -> Void)!
        self.init(promise: Promise { seal in
            reject = seal.reject
            seal.reject(error)
        })
        self.appendCancellable(cancellable, reject: reject)
    }
    
    /// Initialize a new cancellable promise bound to the provided `Thenable`.
    public convenience init<U: Thenable>(_ bridge: U, cancelContext: CancelContext? = nil) where U.T == T {
        var promise: Promise<U.T>!
        let cancellable: Cancellable!
        var reject: ((Error) -> Void)!

        if let p = bridge as? Promise<U.T> {
            cancellable = p.cancellable
            if let r = p.rejectIfCancelled {
                promise = p
                reject = r
            }
        } else if let g = bridge as? Guarantee<U.T> {
            cancellable = g.cancellable
        } else {
            cancellable = nil
        }
        
        if promise == nil {
            // Wrapper promise
            promise = Promise { seal in
                reject = seal.reject
                bridge.done(on: nil) {
                    seal.fulfill($0)
                }.catch(policy: .allErrors) {
                    seal.reject($0)
                }
            }
        }

        self.init(promise: promise, context: cancelContext)
        self.appendCancellable(cancellable, reject: reject)
    }
    
    /// Initialize a new cancellable promise that can be resolved with the provided `Resolver`.
    public convenience init(cancellable: Cancellable? = nil, resolver body: (Resolver<T>) throws -> Void) {
        var reject: ((Error) -> Void)!
        self.init(promise: Promise { seal in
            reject = seal.reject
            try body(seal)
        })
        self.appendCancellable(cancellable, reject: reject)
    }
    
    /// Initialize a new cancellable promise using the given Promise and its Resolver.
    public convenience init(cancellable: Cancellable? = nil, promise: Promise<T>, resolver: Resolver<T>) {
        self.init(promise: promise)
        self.appendCancellable(cancellable, reject: resolver.reject)
    }

    /// - Returns: a tuple of a new cancellable pending promise and its `Resolver`.
    public class func pending() -> (promise: CancellablePromise<T>, resolver: Resolver<T>) {
        let rp = Promise<T>.pending()
        return (promise: CancellablePromise(promise: rp.promise), resolver: rp.resolver)
    }
    
    /// Internal function required for `Thenable` conformance.
    /// - See: `Thenable.pipe`
    public func pipe(to: @escaping (Result<T, Error>) -> Void) {
        promise.pipe(to: to)
    }
    
    /// - Returns: The current `Result` for this cancellable promise.
    /// - See: `Thenable.result`
    public var result: Result<T, Error>? {
        return promise.result
    }

    /**
     Blocks this thread, so—you know—don’t call this on a serial thread that
     any part of your chain may use. Like the main thread for example.
     */
    public func wait() throws -> T {
        return try promise.wait()
    }
}

#if swift(>=3.1)
extension CancellablePromise where T == Void {
    /// Initializes a new cancellable promise fulfilled with `Void`
    public convenience init() {
        self.init(promise: Promise())
    }

    /// Initializes a new cancellable promise fulfilled with `Void` and with the given ` Cancellable`
    public convenience init(cancellable: Cancellable) {
        self.init()
        self.appendCancellable(cancellable, reject: nil)
    }
}
#endif
