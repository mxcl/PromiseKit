/**
 AnyPromise is a promise designed for Objective-C.
*/
@objc(AnyPromise) public final class AnyPromise: NSObject, PromiseMixin {

    let state: State<Any?>

    /// - Returns: A new `AnyPromise` bound to a `Promise`.
    public init<T>(_ bridge: Promise<T>) {
        switch bridge.state.get() {
        case .fulfilled(let value)?:
            state = SealedState(result: .fulfilled(value))
        case .rejected(let error)?:
            state = SealedState(result: .rejected(error))
        case nil:
            state = bridge.then(on: nil, execute: Optional<Any>.init).state
        }
    }

    init(state: State<Any?>) {
        self.state = state
    }

    private init(sealant: (@escaping (Result<Any?>) -> Void) -> Void) {
        var resolve: ((Result<Any?>) -> Void)!
        state = UnsealedState(resolver: &resolve)
        sealant(resolve)
    }

//MARK: ObjC methods

    /**
     The value of the asynchronous task this promise represents.

     A promise has `nil` value if the asynchronous task it represents has not finished. If the value is `nil` the promise is still `pending`.

     - Warning: *Note* Our Swift variant’s value property returns nil if the promise is rejected where AnyPromise will return the error object. This fits with the pattern where AnyPromise is not strictly typed and is more dynamic, but you should be aware of the distinction.
     
     - Note: If the AnyPromise was fulfilled with a `PMKManifold`, returns only the first fulfillment object.

     - Returns: The value with which this promise was resolved or `nil` if this promise is pending.
     */
    @objc private var __value: Any? {
        switch state.get() {
        case nil:
            return nil
        case .rejected(let error)?:
            return error
        case .fulfilled(let obj)?:
            return obj
        }
    }

    /**
     Creates a resolved promise.

     When developing your own promise systems, it is occasionally useful to be able to return an already resolved promise.

     - Parameter value: The value with which to resolve this promise. Passing an `NSError` will cause the promise to be rejected, passing an AnyPromise will return a new AnyPromise bound to that promise, otherwise the promise will be fulfilled with the value passed.

     - Returns: A resolved promise.
     */
    @objc public class func promiseWithValue(_ value: Any?) -> AnyPromise {
        let state: State<Any?>
        switch value {
        case let promise as AnyPromise:
            state = promise.state
        case let err as Error:
            state = SealedState(result: .rejected(err))
        default:
            state = SealedState(result: .fulfilled(value))
        }
        return AnyPromise(state: state)
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
    @objc public class func promiseWithResolverBlock(_ body: (@escaping (Any?) -> Void) -> Void) -> AnyPromise {
        return AnyPromise { resolve in
            body { obj in
                makeHandler({ _ in obj }, resolve)(obj)
            }
        }
    }

    @objc func __then(on q: DispatchQueue, execute body: @escaping (Any?) -> Any?) -> AnyPromise {
        return AnyPromise { resolve in
            state.pipe { result in
                guard case .fulfilled(let value) = result else { return resolve(result) }
                let handler = makeHandler(body, resolve)
                q.async{ handler(value) }
            }
        }
    }

    @objc func __catch(withPolicy policy: CatchPolicy, execute body: @escaping (Any?) -> Any?) -> AnyPromise {
        return AnyPromise { resolve in
            state.pipe { result in
                switch (result, policy) {
                case (.rejected(let error), .allErrorsExceptCancellation) where error.isCancelledError:
                    fallthrough
                case (.fulfilled, _):
                    resolve(result)
                case (.rejected(let error), _):
                    let handler = makeHandler(body, resolve)
                    DispatchQueue.main.async{ handler(error) }
                }
            }
        }
    }

    @objc func __ensure(on q: DispatchQueue, execute body: @escaping () -> Void) -> AnyPromise {
        state.pipe { _ in
            q.async(execute: body)
        }
        return self
    }

    /// used by PMKWhen and PMKJoin
    @objc func __pipe(_ body: @escaping (Any?) -> Void) {
        state.pipe{ body($0.value) }
    }
}

private func makeHandler(_ body: @escaping (Any?) -> Any?, _ resolve: @escaping (Result<Any?>) -> Void) -> (Any?) -> Void {
    return { obj in
        let obj = body(obj)
        switch obj {
        case let err as Error:
            resolve(.rejected(err))
        case let promise as AnyPromise:
            promise.state.pipe(resolve)
        default:
            resolve(.fulfilled(obj))
        }
    }
}
