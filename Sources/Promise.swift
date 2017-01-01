/**
 A *promise* represents the future Wrapped of a (usually) asynchronous task.

 To obtain the Wrapped of a promise we call `then`.

 Promises are chainable: `then` returns a promise, you can call `then` on
 that promise, which returns a promise, you can call `then` on that
 promise, et cetera.

 Promises start in a pending state and *resolve* with a Wrapped to become
 *fulfilled* or an `Error` to become rejected.

 - SeeAlso: [PromiseKit 101](http://promisekit.org/docs/)
 */
public final class Promise<Wrapped>: PromiseMixin {
    let state: State<Wrapped>

    init(state: State<Wrapped>) {
        self.state = state
    }

    /**
     Create an already resolved promise.
     
     - Note: Usually promises start pending, but sometimes you need a promise that has already transitioned to the “rejected” state.
     */
    public convenience init(_ result: Result<Wrapped>) {
        self.init(state: SealedState(result: result))
    }

    /**
     Create an already fulfilled promise.
     
     - Note: Usually promises start pending, but sometimes you need a promise that has already transitioned to the “fulfilled” state.
     */
    public convenience init(_ Wrapped: Wrapped) {
        self.init(state: SealedState(result: .fulfilled(Wrapped)))
    }

    /**
     Create an already rejected promise.
     
     - Note: Usually promises start pending, but sometimes you need a promise that has already transitioned to the “rejected” state.
     */
    public convenience init(error: Error) {
        self.init(state: SealedState(result: .rejected(error)))
    }

    /**
     Create a new, pending promise.

         func fetchAvatar(user: String) -> Promise<UIImage> {
             return Promise { pipe in
                 MyWebHelper.GET("\(user)/avatar") { data, err in
                     guard let data = data else { return pipe.reject(err) }
                     guard let img = UIImage(data: data) else { return pipe.reject(MyError.InvalidImage) }
                     guard let img.size.width > 0 else { return pipe.reject(MyError.ImageTooSmall) }
                     pipe.fulfill(img)
                 }
             }
         }

     - Parameter pipe: The provided closure is called immediately on the current queue; commence your asynchronous task, calling either `pipe.fulfill` or `pipe.reject` when it completes.
     - Returns: A new promise.
     - Note: It is usually easier to use `PromiseKit.wrap`.
     - Note: If you are wrapping a delegate-based system, we recommend to use instead: `Promise.pending()`
     - SeeAlso: http://promisekit.org/docs/sealing-promises/
     - SeeAlso: http://promisekit.org/docs/cookbook/wrapping-delegation/
     - SeeAlso: pending()
     */
    public convenience init(pipe callback: (Pipe<Wrapped>) throws -> Void) {
        let pipe = Pipe<Wrapped>()
        do {
            self.init(state: UnsealedState(resolver: &pipe._resolve))
            try callback(pipe)
        } catch {
            pipe.reject(error)
        }
    }

    /**
     Returns a promise that assumes the state of another promise.
 
     Convenient for catching errors for any preamble in creating initial promises, or for various other patterns that would otherwise be ugly or unclear in the resulting code. For example:
 
         return Promise {
             guard let url = /**/ else { throw Error.badUrl }
             return URLSession.shared.dataTask(url: url)
         }
     
     Which otherwise would require a `firstly` (which would read poorly since here there is no subsequent `then`) or for all to be surrounding in a `do`, `catch` and then a rejected promise generated and returned in the catch.
     
     - Remark: `return` was chosen rather than passing in a `pipe` function since you cannot forget to `return`.

     */
    public convenience init<Promise: Chainable>(bind body: () throws -> Promise) where Promise.Wrapped == Wrapped {
        do {
            self.init(state: try body().state)
        } catch {
            self.init(error: error)
        }
    }

    //TODO we want `Self` and *not* `Promise`
    public typealias Pending = (promise: Promise, pipe: Pipe<Wrapped>)

    /**
     Making promises that wrap asynchronous delegation systems or other larger asynchronous systems without a simple completion handler is easier with pending.

         class Foo: BarDelegate {
             let (promise, pipe) = Promise<Int>.pending()
    
             func barDidFinishWithResult(result: Int) {
                 pipe.resolve(result)
             }
    
             func barDidError(error: NSError) {
                 pipe.resolve(error)
             }
         }

     - Returns: A promise and a pipe that can resolve it.
     */
    public static func pending() -> Pending {
        let pipe = Pipe<Wrapped>()
        let state = UnsealedState(resolver: &pipe._resolve)
        let promise = Promise(state: state)
        return (promise, pipe)
    }


    /**
     Our `Pipe` is less efficient due to Promises/A+, so we use this internally.
     */
    static func _pending() -> (promise: Promise, resolve: (Result<Wrapped>) -> Void) {
        var resolve: ((Result<Wrapped>) -> Void)!
        let state = UnsealedState<Wrapped>(resolver: &resolve)
        let promise = Promise(state: state)
        return (promise, resolve)
    }

    /**
     Pipes the Wrapped of this promise to the provided function.

     - Parameter to: The pipe of another promise that we will “pipe” our state to.
     - SeeAlso: `pending() -> (Promise, Joint)`
     - Remark: Wrapped in a pipe rather than allowing any `(Result) -> Void` because we do this on the current queue and need exactly defined behavior for what the function this calls does. `tap` is basically the same function, but it has a defined queue so it takes a `Result` closure.
     - Todo: We should probably immediately reject if the pipe will pipe to `self`
     */
    public func pipe(to pipe: Pipe<Wrapped>) {
        state.pipe(pipe.resolve)
    }

    /**
     Void promises are less prone to generics-of-doom scenarios.
     - SeeAlso: when.swift contains enlightening examples of using `Promise<Void>` to simplify your code.
     */
    public func asVoid() -> Promise<Void> {
        let (promise, resolve) = Promise<Void>._pending()
        state.pipe{ result in
            switch result {
            case .fulfilled:
                resolve(.fulfilled())
            case .rejected(let error):
                resolve(.rejected(error))
            }
        }
        return promise
    }
}

extension Promise where Wrapped: Collection {
    /**
     Transforms a `Promise` where `T` is a `Collection` into a `Promise<[U]>`
     
         func download(urls: [String]) -> Promise<UIImage> {
             //…
         }

         return URLSession.shared.dataTask(url: url).asArray().map(download)

     Equivalent to:

         func download(urls: [String]) -> Promise<UIImage> {
             //…
         }

         return URLSession.shared.dataTask(url: url).then { urls in
             return when(fulfilled: urls.map(download))
         }


     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter transform: The closure that executes when this promise resolves.
     - Returns: A new promise, resolved with this promise’s resolution.
     */
    public final func map<U>(on q: DispatchQueue? = .default, transform: @escaping (Wrapped.Iterator.Element) throws -> Promise<U>) -> Promise<[U]>
    {
        return then(on: q) { when(fulfilled: try $0.map(transform)) }
    }
}

/**
 Judicious use of `firstly` *may* make chains more readable.

 Compare:

     NSURLSession.dataTask(url: url1).then {
         URLSession.shared.dataTask(url: url2)
     }.then {
         URLSession.shared.dataTask(url: url3)
     }

 With:

     firstly {
         URLSession.shared.dataTask(url: url1)
     }.then {
         URLSession.shared.dataTask(url: url2)
     }.then {
         URLSession.shared.dataTask(url: url3)
     }
 */
public func firstly<ReturnType: Chainable>(execute body: () throws -> ReturnType) -> Promise<ReturnType.Wrapped> {
    do {
        return try body().promise
    } catch {
        return Promise(error: error)
    }
}

public class Pipe<Wrapped> {

#if !PMKDisableWarnings
    var called = false

    deinit {
        if !called {
            NSLog("PromiseKit: warning: `Promise(pipe:)` not resolved, this is usually a bug.")
        }
    }
#endif

    fileprivate var _resolve: ((Result<Wrapped>) -> Void)!

    public func resolve(_ result: Result<Wrapped>) {
    #if !PMKDisableWarnings
        if called {
            NSLog("PromiseKit: information: resolve is being called an already resolved promise.")
        } else {
            called = true   //TODO thread safety!
        }
    #endif

        //FIXME THIS SUCKS
        // there should be a more optimal way to do this
        //
        // var foo = 1
        // after(1) {
        //     fulfill()
        //     foo += 1
        // }
        // promise.then {
        //     foo += 1
        // }
        //
        // Above is reason for the exeCtx, foo should be incremented DETERMINISTICALLY
        //
        // one way would be to return something since nothing can happen after the return?
        Thread.current.afterExecutionContext {
            self._resolve(result)
        }
    }

    public func reject(_ error: Error) {
        resolve(.rejected(error))
    }
    public func reject<U>(_ result: Result<U>) {
        resolve(.rejected(result.value as! Error))
    }
    public func fulfill(_ Wrapped: Wrapped) {
        resolve(.fulfilled(Wrapped))
    }
    
    /**
     This variant of resolve is convenient when wrapping asynchronous systems that
     use common patterns. For example:

         func fetchImage() -> Promise<UIImage> {
             return Promise { API.fetchImage(withCompletion: $0.resolve) }
         }

     Where:

         struct API {
             func fetchImage(withCompletion: (UIImage?, Error?) -> Void) {
                 // you or a third party provided this implementation
             }
         }
     */
    public func resolve(_ body: @escaping (Wrapped?, Error?) -> Void) {
        try body { obj, err in
            if let err = err {
                reject(err)
            } else if let obj = obj {
                fulfill(obj)
            } else {
                reject(PMKError.invalidCallingConvention)
            }
        }
    }
    
    /**
     This variant of resolve is convenient when wrapping asynchronous systems that
     use common patterns. For example:

         func fetch() -> Promise<FetchResult> {
             return Promise { API.fetch(withCompletion: $0.resolve) }
         }

     Where:

         enum FetchResult { /*…*/ }

         struct API {
             func fetchImage(withCompletion: (FetchResult, Error?) -> Void) {
                 // you or a third party provided this implementation
             }
         }
    
     - Note: This implies the `FetchResult` enum has an error `case`, which you
       thus lose. If you need to access this value you should handle the completion
       handler yourself.
     */
    public func resolve(_ body: (@escaping (Wrapped, Error?) -> Void) throws -> Void) {
        try body { obj, err in
            if let err = err {
                reject(err)
            } else {
                fulfill(obj)
            }
        }
    }
    
    /**
     This variant of resolve is provided so our initializer works, *even* if 
     the API you are wrapping got the calling convention for completion handlers
     inverted.
    
         func fetchImage() -> Promise<UIImage> {
             return Promise { API.fetchImage(withCompletion: $0.resolve) }
         }
    
     Where:
    
         func fetchImage(withCompletion: (Error?, UIImage?) -> Void) {
             // you or a third party provided this implementation
         }
    
     */
    public func resolve(_ body: (@escaping (Error?, Wrapped?) -> Void) throws -> Void) {
        try body { err, obj in
            if let err = err {
                reject(err)
            } else if let obj = obj {
                fulfill(obj)
            } else {
                reject(PMKError.invalidCallingConvention)
            }
        }
    }

    /**
     This variant of resolve is provided for APIs that can error, but provide
     no meaningful result if they succeed. It really only makes sense for
     `Wrapped: Void`.
    
         func validate() -> Promise<Void> {
             return Promise { validate(withCompletion: $0.resolve) }
         }
    
     Where:
    
         func validate(withCompletion: (Error?) -> Void) {
             // you or a third party provided this implementation
         }
    
     */
    public func resolve(defaultValue: Wrapped = Wrapped(), body: (@escaping (Error?) -> Void) throws -> Void) {
        try body { error in
            if let error = error {
                reject(error)
            } else {
                fulfill()
            }
        }
    }
    
    /// For completions that cannot error. TODO should use unfailable promise
    public func wrap<T>(_ body: (@escaping (T) -> Void) throws -> Void) -> Promise<T> {
        return Promise { pipe in
            try body{ pipe.fulfill($0) }
        }
    }
    
}
