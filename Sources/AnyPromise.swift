import Foundation

/**
 More accurately, AnyObjectPromise, since AnyPromise is
 our Objective-C bridge, thus AnyPromise can only represent
 objects, not value-types (structs).
*/
@objc(AnyPromise) public class AnyPromise: NSObject {
    let state: State<AnyObject?>

    /**
     - Returns: A new `AnyPromise` bound to a `Promise<AnyObject?>`.
    */
    required public init(_ bridge: Promise<AnyObject?>) {
        state = bridge.state
    }

    /// hack so Swift picks the right initializer for each of the below
    private init(force: Promise<AnyObject?>) {
        state = force.state
    }

    /**
     - Returns: A new `AnyPromise` bound to a `Promise<T>`.
    */
    public convenience init<T: AnyObject>(_ bridge: Promise<T?>) {
        self.init(force: bridge.then(on: zalgo) { $0 })
    }

    /**
     - Returns: A new `AnyPromise` bound to a `Promise<T>`.
    */
    convenience public init<T: AnyObject>(_ bridge: Promise<T>) {
        self.init(force: bridge.then(on: zalgo, execute: Optional.init))
    }

    /**
     - Returns: A new `AnyPromise` bound to a `Promise<[T]>`.
     - Note: The array is converted to an `NSArray`.
    */
    convenience public init<T: AnyObject>(_ bridge: Promise<[T]>) {
        self.init(force: bridge.then(on: zalgo) { NSArray(array: $0) })
    }

    /**
     - Returns: A new `AnyPromise` bound to a `Promise<[T:U]>`.
     - Note: The dictionary value is converted to an `NSDictionary`.
    */
    convenience public init<T: AnyObject, U: AnyObject>(_ bridge: Promise<[T:U]>) {
        self.init(force: bridge.then(on: zalgo) { NSDictionary(dictionary: $0) })
    }

    /**
     - Returns: A new `AnyPromise` bound to a `Promise<String>`.
     - Note: The `String` is converted to an `NSString`.
     */
    convenience public init(_ bridge: Promise<String>) {
        self.init(force: bridge.then(on: zalgo, execute: NSString.init))
    }

    /**
     - Returns: A new `AnyPromise` bound to a `Promise<Int>`.
     - Note: The integer value is converted to an `NSNumber`.
    */
    convenience public init(_ bridge: Promise<Int>) {
        self.init(force: bridge.then(on: zalgo) { NSNumber(value: $0) })
    }

    /**
     - Returns: A new `AnyPromise` bound to a `Promise<Bool>`.
     - Note: The boolean value is converted to an `NSNumber`.
     */
    convenience public init(_ bridge: Promise<Bool>) {
        self.init(force: bridge.then(on: zalgo) { NSNumber(value: $0) })
    }

    /**
     - Returns: A new `AnyPromise` bound to a `Promise<Void>`.
     - Note: A “void” `AnyPromise` has a value of `nil`.
    */
    convenience public init(_ bridge: Promise<Void>) {
        self.init(force: bridge.then(on: zalgo) { nil })
    }

    /**
     Bridge an AnyPromise to a Promise<AnyObject?>
     - Note: AnyPromises fulfilled with `PMKManifold` lose all but the first fulfillment object.
     - Remark: Could not make this an initializer of `Promise` due to generics issues.
     */
    public func asPromise() -> Promise<AnyObject?> {
        return Promise(sealant: { resolve in
            state.pipe { resolution in
                switch resolution {
                case .rejected:
                    resolve(resolution)
                case .fulfilled(let obj):
                    resolve(.fulfilled(unwrapManifold(obj)))
                }
            }
        })
    }

    /// - See: `Promise.then()`
    public func then<T>(on q: DispatchQueue = PMKDefaultDispatchQueue(), execute body: (AnyObject?) throws -> T) -> Promise<T> {
        return asPromise().then(on: q, execute: body)
    }

    /// - See: `Promise.then()`
    public func then(on q: DispatchQueue = PMKDefaultDispatchQueue(), execute body: (AnyObject?) throws -> AnyPromise) -> Promise<AnyObject?> {
        return asPromise().then(on: q, execute: body)
    }

    /// - See: `Promise.then()`
    public func then<T>(on q: DispatchQueue = PMKDefaultDispatchQueue(), execute body: (AnyObject?) throws -> Promise<T>) -> Promise<T> {
        return asPromise().then(on: q, execute: body)
    }

    /// - See: `Promise.always()`
    public func always(on q: DispatchQueue = PMKDefaultDispatchQueue(), execute body: () -> Void) -> Promise<AnyObject?> {
        return asPromise().always(execute: body)
    }

    /// - See: `Promise.tap()`
    public func tap(on q: DispatchQueue = PMKDefaultDispatchQueue(), execute body: (Result<AnyObject?>) -> Void) -> Promise<AnyObject?> {
        return asPromise().tap(execute: body)
    }

    /// - See: `Promise.recover()`
    public func recover(on q: DispatchQueue = PMKDefaultDispatchQueue(), policy: CatchPolicy = .allErrorsExceptCancellation, execute body: (ErrorProtocol) throws -> Promise<AnyObject?>) -> Promise<AnyObject?> {
        return asPromise().recover(on: q, policy: policy, execute: body)
    }

    /// - See: `Promise.recover()`
    public func recover(on q: DispatchQueue = PMKDefaultDispatchQueue(), policy: CatchPolicy = .allErrorsExceptCancellation, execute body: (ErrorProtocol) throws -> AnyObject?) -> Promise<AnyObject?> {
        return asPromise().recover(on: q, policy: policy, execute: body)
    }

    /// - See: `Promise.catch()`
    public func `catch`(on q: DispatchQueue = PMKDefaultDispatchQueue(), policy: CatchPolicy = .allErrorsExceptCancellation, execute body: (ErrorProtocol) -> Void) {
        state.catch(on: q, policy: policy, else: { _ in }, execute: body)
    }

//MARK: ObjC methods

    /**
     A promise starts pending and eventually resolves.
     - Returns: `true` if the promise has not yet resolved.
     */
    @objc public var pending: Bool {
        return state.get() == nil
    }

    /**
     A promise starts pending and eventually resolves.
     - Returns: `true` if the promise has resolved.
     */
    @objc public var resolved: Bool {
        return !pending
    }

    /**
     The value of the asynchronous task this promise represents.

     A promise has `nil` value if the asynchronous task it represents has not finished. If the value is `nil` the promise is still `pending`.

     - Warning: *Note* Our Swift variant’s value property returns nil if the promise is rejected where AnyPromise will return the error object. This fits with the pattern where AnyPromise is not strictly typed and is more dynamic, but you should be aware of the distinction.
     
     - Note: If the AnyPromise was fulfilled with a `PMKManifold`, returns only the first fulfillment object.

     - Returns If `resolved`, the object that was used to resolve this promise; if `pending`, nil.
     */
    @objc public var value: AnyObject? {
        switch state.get() {
        case nil:
            return nil
        case .rejected(let error, _)?:
            return error as NSError
        case .fulfilled(let obj)?:
            return unwrapManifold(obj)
        }
    }

    /**
     Creates a resolved promise.

     When developing your own promise systems, it is ocassionally useful to be able to return an already resolved promise.

     - Parameter value: The value with which to resolve this promise. Passing an `NSError` will cause the promise to be rejected, passing an AnyPromise will return a new AnyPromise bound to that promise, otherwise the promise will be fulfilled with the value passed.

     - Returns: A resolved promise.
     */
    @objc class func promiseWithValue(_ value: AnyObject?) -> AnyPromise {
        let state: State<AnyObject?>
        switch value {
        case let promise as AnyPromise:
            state = promise.state
        case let err as NSError:
            state = SealedState(resolution: Resolution(err))
        default:
            state = SealedState(resolution: .fulfilled(value))
        }
        return AnyPromise(state: state)
    }

    private init(state: State<AnyObject?>) {
        self.state = state
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
    @objc class func promiseWithResolverBlock(_ body: ((AnyObject?) -> Void) -> Void) -> AnyPromise {
        return AnyPromise(sealant: { resolve in
            body { obj in
                makeHandler({ _ in obj }, resolve)(obj)
            }
        })
    }

    private init(sealant: @noescape ((Resolution<AnyObject?>) -> Void) -> Void) {
        var resolve: ((Resolution<AnyObject?>) -> Void)!
        state = UnsealedState(resolver: &resolve)
        sealant(resolve)
    }

    @objc func __thenOn(_ q: DispatchQueue, execute body: (AnyObject?) -> AnyObject?) -> AnyPromise {
        return AnyPromise(sealant: { resolve in
            state.then(on: q, else: resolve, execute: makeHandler(body, resolve))
        })
    }

    @objc func __catchWithPolicy(_ policy: CatchPolicy, execute body: (AnyObject?) -> AnyObject?) -> AnyPromise {
        return AnyPromise(sealant: { resolve in
            state.catch(on: PMKDefaultDispatchQueue(), policy: policy, else: resolve) { err in
                makeHandler(body, resolve)(err as NSError)
            }
        })
    }

    @objc func __alwaysOn(_ q: DispatchQueue, execute body: () -> Void) -> AnyPromise {
        return AnyPromise(sealant: { resolve in
            state.always(on: q) { resolution in
                body()
                resolve(resolution)
            }
        })
    }

    /// used by PMKWhen and PMKJoin
    @objc func __pipe(_ body: (AnyObject?) -> Void) {
        state.pipe { resolution in
            switch resolution {
            case .rejected(let error, let token):
                token.consumed = true  // when and join will create a new parent error that is unconsumed
                body(error as NSError)
            case .fulfilled(let value):
                body(value)
            }
        }
    }
}


extension AnyPromise {
    override public var description: String {
        return "AnyPromise: \(state)"
    }
}

private func unwrapManifold(_ obj: AnyObject?) -> AnyObject? {
    if let obj = obj, let kind = NSClassFromString("PMKArray"), obj.isKind(of: kind) {
        // - SeeAlso: PMKManifold
        return obj[0]
    } else {
        return obj
    }
}

private func makeHandler(_ body: (AnyObject?) -> AnyObject?, _ resolve: (Resolution<AnyObject?>) -> Void) -> (AnyObject?) -> Void {
    return { obj in
        let obj = body(obj)
        switch obj {
        case let err as NSError:
            resolve(Resolution(err))
        case let promise as AnyPromise:
            promise.state.pipe(resolve)
        default:
            resolve(.fulfilled(obj))
        }
    }
}
