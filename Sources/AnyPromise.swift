import Foundation

/**
 AnyPromise is an Objective-C compatible promise.
*/
@objc(AnyPromise) public class AnyPromise: NSObject, Thenable, CatchMixin {
    fileprivate let box: Box<Any?>

    /// - Returns: A new `AnyPromise` bound to a `Promise<Any>`.
    public init<U: Thenable>(_ bridge: U) {
        box = EmptyBox()
        super.init()
        bridge.pipe {
            switch $0 {
            case .rejected(let error):
                self.box.seal(error)
            case .fulfilled(let value):
                self.box.seal(value)
            }
        }
    }

    fileprivate init(box: Box<Any?>) {
        self.box = box
    }

    public func pipe(to body: @escaping (Result<Any?>) -> Void) {
        sewer {
            switch $0 {
            case .fulfilled:
                // calling through to the ObjC `value` property unwraps (any) PMKManifold
                body(.fulfilled(self.value(forKey: "value")))
            case .rejected:
                body($0)
            }
        }
    }

    public var result: Result<Any?>? {
        switch box.inspect() {
        case .pending:
            return nil
        case .resolved(let obj as Error):
            return .rejected(obj)
        case .resolved(let value):
            return .fulfilled(value)
        }
    }

    fileprivate func sewer(to body: @escaping (Result<Any?>) -> Void) {
        switch box.inspect() {
        case .pending:
            box.inspect {
                switch $0 {
                case .pending(let handlers):
                    handlers.append {
                        if let error = $0 as? Error {
                            body(.rejected(error))
                        } else {
                            body(.fulfilled($0))
                        }
                    }
                case .resolved(let error as Error):
                    body(.rejected(error))
                case .resolved(let value):
                    body(.fulfilled(value))
                }
            }
        case .resolved(let error as Error):
            body(.rejected(error))
        case .resolved(let value):
            body(.fulfilled(value))
        }
    }
}

internal extension AnyPromise {
    @objc private var __value: Any? {
        switch box.inspect() {
        case .pending:
            return nil
        case .resolved(let obj):
            return obj
        }
    }

    @objc private var __pending: Bool {
        switch box.inspect() {
        case .pending:
            return true
        case .resolved:
            return false
        }
    }

    /**
     Creates a resolved promise.

     When developing your own promise systems, it is occasionally useful to be able to return an already resolved promise.

     - Parameter value: The value with which to resolve this promise. Passing an `NSError` will cause the promise to be rejected, passing an AnyPromise will return a new AnyPromise bound to that promise, otherwise the promise will be fulfilled with the value passed.

     - Returns: A resolved promise.
     */
    @objc class func promiseWithValue(_ value: Any?) -> AnyPromise {
        switch value {
        case let promise as AnyPromise:
            return promise
        default:
            return AnyPromise(box: SealedBox(value: value))
        }
    }

    /**
     Create a new promise that resolves with the provided block.

     Use this method when wrapping asynchronous code that does *not* use promises so that this code can be used in promise chains.

     If `resolve` is called with an `NSError` object, the promise is rejected, otherwise the promise is fulfilled.

     Don’t use this method if you already have promises! Instead, just return your promise.

     Should you need to fulfill a promise but have no sensical value to use: your promise is a `void` promise: fulfill with `nil`.

     The block you pass is executed immediately on the calling thread.

     - Parameter block: The provided block is immediately executed, inside the block call `resolve` to resolve this promise and cause any attached handlers to execute. If you are wrapping a delegate-based system, we recommend instead to use: initWithResolver:

     - Returns: A new promise.
     - Warning: Resolving a promise with `nil` fulfills it.
     - SeeAlso: http://promisekit.org/sealing-your-own-promises/
     - SeeAlso: http://promisekit.org/wrapping-delegation/
     */
    @objc class func promiseWithResolverBlock(_ body: (@escaping (Any?) -> Void) -> Void) -> AnyPromise {
        let box = EmptyBox<Any?>()
        let rap = AnyPromise(box: box)
        body { AnyPromise.apply($0, box) }
        return rap
    }

    private static func apply(_ value: Any?, _ box: Box<Any?>) {
        switch value {
        case let p as AnyPromise:
            p.__pipe{ apply($0, box) }
        default:
            box.seal(value)
        }
    }

    @objc private func __thenOn(_ q: DispatchQueue, execute body: @escaping (Any?) -> Any?) -> AnyPromise {
        let box = EmptyBox<Any?>()
        let rap = AnyPromise(box: box)
        ___pipe {
            switch $0 {
            case .rejected(let error):
                box.seal(error)
            case .fulfilled(let value):
                q.async {
                    AnyPromise.apply(body(value), box)
                }
            }
        }
        return rap

    }

    @objc private func __catchOn(_ q: DispatchQueue, execute body: @escaping (Any?) -> Any?) -> AnyPromise {
        let box = EmptyBox<Any?>()
        let rap = AnyPromise(box: box)
        ___pipe {
            switch $0 {
            case .rejected(let error):
                q.async {
                    AnyPromise.apply(body(error), box)
                }
            case .fulfilled(let value):
                box.seal(value)
            }
        }
        return rap
    }

    @objc private func __alwaysOn(_ q: DispatchQueue, execute body: @escaping () -> Void) -> AnyPromise {
        let box = EmptyBox<Any?>()
        let rap = AnyPromise(box: box)
        __pipe { obj in
            q.async {
                body()
                box.seal(obj)
            }
        }
        return rap
    }

    /// converts NSErrors, feeds raw PMKManifolds
    /// exposed to ObjC for use in a few places
    @objc private func __pipe(_ body: @escaping (Any?) -> Void) {
        sewer {
            switch $0 {
            case .fulfilled(let value):
                body(value)
            case .rejected(let error):
                body(error as NSError)
            }
        }
    }

    /// converts NSErrors, feeds raw PMKManifolds
    private func ___pipe(to body: @escaping (Result<Any?>) -> Void) {
        sewer {
            switch $0 {
            case .fulfilled:
                body($0)
            case .rejected(let error):
                body(.rejected(error as NSError))
            }
        }
    }
}


extension AnyPromise {
    /// - Returns: A description of the state of this promise.
    override public var description: String {
        switch box.inspect() {
        case .pending:
            return "AnyPromise(…)"
        case .resolved(let obj?):
            return "AnyPromise(\(obj))"
        case .resolved(nil):
            return "AnyPromise(nil)"
        }
    }
}


#if swift(>=3.1)
public extension Promise where T == Any? {
    convenience init(_ anyPromise: AnyPromise) {
        self.init(.pending) {
            anyPromise.pipe(to: $0.resolve)
        }
    }
}
#else
extension AnyPromise {
    public func asPromise() -> Promise<Any?> {
        return Promise(.pending, resolver: { resolve in
            pipe { result in
                switch result {
                case .rejected(let error):
                    resolve.reject(error)
                case .fulfilled(let obj):
                    resolve.fulfill(obj)
                }
            }
        })
    }
}
#endif
