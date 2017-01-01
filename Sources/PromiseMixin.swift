import Dispatch

//TODO then that takes a QoS then implicitly backgrounds it

/// - Remark: This protocol exists to allow `AnyPromise` and `Promise` to share an interface without forcing `Promise` to derive `NSObject`
protocol PromiseMixin: class {
    associatedtype Wrapped

    init(state: State<Wrapped>)
    var state: State<Wrapped> { get }
}

private enum Continuation<ReturnType: Chainable> {
    case async(() throws -> ReturnType)
    case sync(Result<ReturnType.Wrapped>)
}

extension PromiseMixin {

    private init<U: PromiseMixin, ReturnType: Chainable>(when: U, on q: DispatchQueue?, execute body: @escaping (Result<U.Wrapped>) -> Continuation<ReturnType>) where ReturnType.Wrapped == Wrapped
    {
        var resolve: ((Result<Wrapped>) -> Void)!
        let state = UnsealedState(resolver: &resolve)
        self.init(state: state)

        when.pipe(on: q) { result, async in
            switch body(result) {
            case .sync(let result):
                resolve(result)
            case .async(let body):
                async {
                    do {
                        let promise = try body().promise
                        guard promise !== self else { throw PMKError.returnedSelf }
                        promise.state.pipe(resolve)
                    } catch {
                        resolve(.rejected(error))
                    }
                }
            }
        }
    }

    private final func pipe(on q: DispatchQueue?, execute body: @escaping (Result<Wrapped>, (@escaping () -> Void) -> Void) -> Void) {

        //TODO make backtraces better, provide instead a protocol or something that therefore is a noop in noop-ably cases?
        let async: (@escaping () -> Void) -> Void

        if let q = q {
            let exectx = ExecutionContext()

            async = { body in
                exectx.doit {
                    q.maybe(async: body)
                }
            }
        } else {
            async = { $0() }
        }

        state.pipe{ body($0, async) }
    }

    /**
     The provided closure executes when this promise resolves.

     This variant of `then` allows chaining promises, the promise returned by the provided closure is resolved before the promise returned by this closure resolves.

     For example:
     
         URLSession.GET(url1).then { data in
             return CLLocationManager.promise()
         }.then { location in
             //…
         }

     If you return a tuple of promises, all promises are waited on using `when(fulfilled:)`:
     
         login().then { userUrl, avatarUrl in
             (URLSession.GET(userUrl), URLSession.dataTask(with: avatarUrl).asImage())
         }.then { userData, avatarImage in
             //…
         }
     
     If you need to wait on an array of promises, use `when(fulfilled:)`.
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter execute: The closure that executes when this promise fulfills.
     - Returns: A new promise that resolves once the promise returned by `execute` resolves.
     - Important: The default queue is the main queue. If you therefore are already on the main queue, what will happen? The answer is: PromiseKit will *dispatch* so that your handler is executed at the next available queue runloop iteration. The reason for this is the phenomenon known as “Zalgo” in the promises community.
     - Remark: `Promise` generic type name chosen for clarity in compile error messages rather than clarity in our code.
     */
    public final func then<ReturnType: Chainable>(on q: DispatchQueue? = .default, execute body: @escaping (Wrapped) throws -> ReturnType) -> Promise<ReturnType.Wrapped> {
        return Promise(when: self, on: q) { result -> Continuation<ReturnType> in
            switch result {
            case .fulfilled(let value):
                return .async({ try body(value) })
            case .rejected(let error):
                return .sync(.rejected(error))
            }
        }
    }

    /**
     `then` but for `Void` return from your closure.
 
     - Returns: A `Promise<Void>` that fulfills once your closure returns.
     - Remark: This function only exists because Swift, as yet, does not allow protocol extension to `Void`, thus in order to prevent complexity to `then` (we are not afraid of complexity in our sources, but are in fact afraid of less usability for you (closure return types are less easily inferred by the compiler) and due to persisting issues with the Swift compiler returning *incorrect* errors when it involves a closure, thus misleading error messages. Thus you have to decide between this and `then` actively :(
     */
    public final func then(on q: DispatchQueue? = .default, execute body: @escaping (Wrapped) throws -> Void) -> Promise<Void> {
        return Promise(when: self, on: q) { result -> Continuation<Promise<Void>> in
            switch result {
            case .fulfilled(let value):
                return .async({ try body(value); return Promise() })
            case .rejected(let error):
                return .sync(.rejected(error))
            }
        }
    }

    /**
     The provided closure executes when this promise rejects.

     Rejecting a promise cascades: rejecting all subsequent promises (unless
     recover is invoked) thus you will typically place your catch at the end
     of a chain. Often utility promises will not have a catch, instead
     delegating the error handling to the caller.

     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter policy: The default policy does not execute your handler for cancellation errors.
     - Parameter execute: The handler to execute if this promise is rejected.
     - Returns: `self`
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     - Important: The promise that is returned is `self`. `catch` cannot affect the chain, in PromiseKit 3 no promise was returned to strongly imply this, however for PromiseKit 4 we started returning a promise so that you can `always` after a catch or return from a function that has an error handler.
     */
    public final func `catch`(on q: DispatchQueue? = .default, policy: CatchPolicy = .allErrorsExceptCancellation, handler body: @escaping (Error) -> Void) {
        pipe(on: q) { result, async in
            switch (result, policy) {
            case (.rejected(let error), .allErrorsExceptCancellation) where error.isCancelledError:
                break
            case (.fulfilled, _):
                break
            case (.rejected(let error), _):
                async{ body(error) }
            }
        }
    }

    public final func fatalCatch(policy: CatchPolicy = .allErrorsExceptCancellation, file: StaticString = #file, line: UInt = #line) {
        self.catch(on: nil, policy: policy) { error in
            fatalError("PromiseKit: fatal: \(error)", file: file, line: line)
        }
    }


    /**
     The provided closure executes when this promise rejects.
     
     Unlike `catch`, `recover` continues the chain provided the closure does not throw. Use `recover` in circumstances where recovering the chain from certain errors is a possibility. For example:
     
         CLLocationManager.promise().recover { error in
             guard error == CLError.unknownLocation else { throw error }
             return CLLocation.Chicago
         }
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter policy: The default policy does not execute your handler for cancellation errors.
     - Parameter execute: The handler to execute if this promise is rejected.
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     */
    public final func recover<ReturnType: Chainable>(on q: DispatchQueue? = .default, policy: CatchPolicy = .allErrorsExceptCancellation, handler body: @escaping (Error) throws -> ReturnType) -> Promise<Wrapped> where ReturnType.Wrapped == Wrapped
    {
        return Promise(when: self, on: q) { result -> Continuation<ReturnType> in
            switch (result, policy) {
            case (.rejected(let error), .allErrorsExceptCancellation) where error.isCancelledError:
                fallthrough
            case (.fulfilled, _):
                return .sync(result)
            case (.rejected(let error), _):
                return .async({ try body(error) })
            }
        }
    }

    /**
     The provided closure executes when this promise resolves.

         firstly {
             UIApplication.shared.networkActivityIndicatorVisible = true
         }.then {
             //…
         }.ensure {
             UIApplication.shared.networkActivityIndicatorVisible = false
         }.catch {
             //…
         }

     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter execute: The closure that executes when this promise resolves.
     - Returns: `self`
     */
    public final func ensure(on q: DispatchQueue? = .default, that body: @escaping () -> Void) -> Self {
        pipe(on: q, execute: { $1(body) })
        return self
    }

    /**
     Allows you to “tap” into a promise chain and inspect its result.
     
     The function you provide is unable to mutate the chain.
 
         NSURLSession.GET(/*…*/).tap{ print($0) }.then { data in
             //…
         }

     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter execute: The closure that executes when this promise resolves.
     - Note: The default behavior for a plain `.tap()` (without parameters) is to `print`
     - Returns: `self`
     */
    public final func tap(on q: DispatchQueue? = .default, _ body: @escaping (Result<Wrapped>) -> Void = { print(#file, $0, separator: ": ") }) -> Self {
        pipe(on: q) { result, async in async { body(result) } }
        return self
    }
}
