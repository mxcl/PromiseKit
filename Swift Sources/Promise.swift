import Foundation



private enum State {
    case Pending(Handlers)
    case Fulfilled(Any)
    case Rejected(Error)
}



public class Promise<T> {
    private let barrier = dispatch_queue_create("org.promisekit.barrier", DISPATCH_QUEUE_CONCURRENT)
    private var _state: State

    private var state: State {
        var result: State?
        dispatch_sync(barrier) { result = self._state }
        return result!
    }

    public var rejected: Bool {
        switch state {
            case .Fulfilled, .Pending: return false
            case .Rejected: return true
        }
    }
    public var fulfilled: Bool {
        switch state {
            case .Rejected, .Pending: return false
            case .Fulfilled: return true
        }
    }
    public var pending: Bool {
        switch state {
            case .Rejected, .Fulfilled: return false
            case .Pending: return true
        }
    }

    /**
      returns the fulfilled value unless the Promise is pending
      or rejected in which case returns `nil`
     */
    public var value: T? {
        switch state {
        case .Fulfilled(let value):
            return (value as! T)
        default:
            return nil
        }
    }

    /**
      returns the rejected error unless the Promise is pending
      or fulfilled in which case returns `nil`
    */
    public var error: NSError? {
        switch state {
        case .Rejected(let error):
            return error
        default:
            return nil
        }
    }

    public init(_ body:(fulfill: (T) -> Void, reject: (NSError) -> Void) -> Void) {
        _state = .Pending(Handlers())

        let resolver = { (newstate: State) -> Void in
            var handlers = Array<()->()>()
            dispatch_barrier_sync(self.barrier) {
                switch self._state {
                case .Pending(let Ω):
                    self._state = newstate
                    handlers = Ω.bodies
                default:
                    break
                }
            }
            for handler in handlers { handler() }
        }

        body(fulfill: { value->() in
            resolver(.Fulfilled(value))
            return
        }, reject: { error in
            if let pmkerror = error as? Error {
                pmkerror.consumed = false
                resolver(.Rejected(pmkerror))
            } else {
                resolver(.Rejected(Error(domain: error.domain, code: error.code, userInfo: error.userInfo)))
            }
        })
    }

    public class func defer() -> (promise:Promise, fulfill:(T) -> Void, reject:(NSError) -> Void) {
        var f: ((T) -> Void)?
        var r: ((NSError) -> Void)?
        let p = Promise{ f = $0; r = $1 }
        return (p, f!, r!)
    }

    public init(value: T) {
        _state = .Fulfilled(value)
    }

    public init(error: NSError) {
        _state = .Rejected(Error(domain: error.domain, code: error.code, userInfo: error.userInfo))
    }

    public func then<U>(onQueue q:dispatch_queue_t = dispatch_get_main_queue(), body:(T) -> U) -> Promise<U> {
        return Promise<U>{ (fulfill, reject) in
            let handler = { ()->() in
                switch self.state {
                case .Rejected(let error):
                    reject(error)
                case .Fulfilled(let value):
                    dispatch_async(q) { fulfill(body(value as! T)) }
                case .Pending:
                    abort()
                }
            }
            switch self.state {
            case .Rejected, .Fulfilled:
                handler()
            case .Pending(let handlers):
                dispatch_barrier_sync(self.barrier) {
                    handlers.append(handler)
                }
            }
        }
    }

    public func then<U>(onQueue q:dispatch_queue_t = dispatch_get_main_queue(), body:(T) -> Promise<U>) -> Promise<U> {
        return Promise<U>{ (fulfill, reject) in
            let handler = { ()->() in
                switch self.state {
                case .Rejected(let error):
                    reject(error)
                case .Fulfilled(let value):
                    dispatch_async(q) {
                        let promise = body(value as! T)
                        switch promise.state {
                        case .Rejected(let error):
                            reject(error)
                        case .Fulfilled(let value):
                            fulfill(value as! U)
                        case .Pending(let handlers):
                            dispatch_barrier_sync(promise.barrier) {
                                handlers.append {
                                    switch promise.state {
                                    case .Rejected(let error):
                                        reject(error)
                                    case .Fulfilled(let value):
                                        fulfill(value as! U)
                                    case .Pending:
                                        abort()
                                    }
                                }
                            }
                        }
                    }
                case .Pending:
                    abort()
                }
            }

            switch self.state {
            case .Rejected, .Fulfilled:
                handler()
            case .Pending(let handlers):
                dispatch_barrier_sync(self.barrier) {
                    handlers.append(handler)
                }
            }

        }
    }

    public func thenInBackground<U>(body:(T) -> U) -> Promise<U> {
        return then(onQueue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), body: body)
    }
    
    public func thenInBackground<U>(body:(T) -> Promise<U>) -> Promise<U> {
        return then(onQueue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), body: body)
    }

    public func catch(onQueue q:dispatch_queue_t = dispatch_get_main_queue(), body:(NSError) -> T) -> Promise<T> {
        return Promise<T>{ (fulfill, _) in
            let handler = { ()->() in
                switch self.state {
                case .Rejected(let error):
                    dispatch_async(q) {
                        error.consumed = true
                        fulfill(body(error))
                    }
                case .Fulfilled(let value):
                    fulfill(value as! T)
                case .Pending:
                    abort()
                }
            }
            switch self.state {
            case .Fulfilled, .Rejected:
                handler()
            case .Pending(let handlers):
                dispatch_barrier_sync(self.barrier) {
                    handlers.append(handler)
                }
            }
        }
    }

    public func catch(onQueue q:dispatch_queue_t = dispatch_get_main_queue(), body:(NSError) -> Void) -> Void {
        let handler = { ()->() in
            switch self.state {
            case .Rejected(let error):
                dispatch_async(q) {
                    error.consumed = true
                    body(error)
                }
            case .Fulfilled:
                break
            case .Pending:
                abort()
            }
        }
        switch self.state {
        case .Fulfilled, .Rejected:
            handler()
        case .Pending(let handlers):
            dispatch_barrier_sync(self.barrier) {
                handlers.append(handler)
            }
        }
    }

    public func catch(onQueue q:dispatch_queue_t = dispatch_get_main_queue(), body:(NSError) -> Promise<T>) -> Promise<T> {
        return Promise<T>{ (fulfill, reject) in

            let handler = { ()->() in
                switch self.state {
                case .Fulfilled(let value):
                    fulfill(value as! T)
                case .Rejected(let error):
                    dispatch_async(q) {
                        error.consumed = true
                        let promise = body(error)
                        switch promise.state {
                        case .Fulfilled(let value):
                            fulfill(value as! T)
                        case .Rejected(let error):
                            dispatch_async(q) { reject(error) }
                        case .Pending(let handlers):
                            dispatch_barrier_sync(promise.barrier) {
                                handlers.append {
                                    switch promise.state {
                                    case .Rejected(let error):
                                        reject(error)
                                    case .Fulfilled(let value):
                                        fulfill(value as! T)
                                    case .Pending:
                                        abort()
                                    }
                                }
                            }
                        }
                    }
                case .Pending:
                    abort()
                }
            }

            switch self.state {
            case .Fulfilled, .Rejected:
                handler()
            case .Pending(let handlers):
                dispatch_barrier_sync(self.barrier) {
                    handlers.append(handler)
                }
            }
        }
    }

    //FIXME adding the queue parameter prevents compilation with Xcode 6.0.1
    public func finally(/*onQueue q:dispatch_queue_t = dispatch_get_main_queue(),*/ body:()->()) -> Promise<T> {
        let q = dispatch_get_main_queue()

        return Promise<T>{ (fulfill, reject) in
            let handler = { ()->() in
                switch self.state {
                case .Fulfilled(let value):
                    dispatch_async(q) {
                        body()
                        fulfill(value as! T)
                    }
                case .Rejected(let error):
                    dispatch_async(q) {
                        body()
                        reject(error)
                    }
                case .Pending:
                    abort()
                }
            }
            switch self.state {
            case .Fulfilled, .Rejected:
                handler()
            case .Pending(let handlers):
                dispatch_barrier_sync(self.barrier) {
                    handlers.append(handler)
                }
            }
        }
    }

    /**
     Immediate resolution of body if the promise is fulfilled.

     Please note, there are good reasons that `then` does not call `body`
     immediately if the promise is already fulfilled. If you don’t understand
     the implications of unleashing zalgo, you should not under any
     cirumstances use this function!
    */
    public func thenUnleashZalgo(body:(T)->Void) -> Void {
        if let obj = value {
            body(obj)
        } else {
            then(body: body)
        }
    }

    public func voidify() -> Promise<Void> {
        // there is no body parameter, so we zalgo it

        let d = Promise<Void>.defer()

        let handler = { ()->() in
            switch self.state {
            case .Fulfilled:
                d.fulfill()
            case .Rejected(let error):
                d.reject(error)
            case .Pending:
                abort()
            }
        }

        switch state {
        case .Fulfilled, .Rejected:
            handler()
        case .Pending(let handlers):
            dispatch_barrier_sync(self.barrier) {
                handlers.append(handler)
            }
        }

        return d.promise
    }
}


public var PMKUnhandledErrorHandler = { (error: NSError) in
    NSLog("%@", "PromiseKit: Unhandled error: \(error)")
}


private class Error : NSError {
    var consumed: Bool = false  //TODO strictly, should be atomic

    deinit {
        if !consumed {
            PMKUnhandledErrorHandler(self)
        }
    }
}



/**
 When accessing handlers from the State enum, the array
 must not be a copy or we stop being thread-safe. Hence
 this class.
*/
private class Handlers: SequenceType {
    var bodies: [()->()] = []

    func append(body: ()->()) {
        bodies.append(body)
    }

    func generate() -> IndexingGenerator<[()->()]> {
        return bodies.generate()
    }

    var count: Int {
        return bodies.count
    }
}



extension Promise: DebugPrintable {
    public var debugDescription: String {
        var state: State?
        dispatch_sync(barrier) {
            state = self._state
        }

        switch state! {
        case .Pending(let handlers):
            var count: Int?
            dispatch_sync(barrier) {
                count = handlers.count
            }
            return "Promise: Pending with \(count!) handlers"
        case .Fulfilled(let value):
            return "Promise: Fulfilled with value: \(value)"
        case .Rejected(let error):
            return "Promise: Rejected with error: \(error)"
        }
    }
}



func dispatch_promise<T>(/*to q:dispatch_queue_t = dispatch_get_global_queue(0, 0),*/ body:() -> AnyObject) -> Promise<T> {
    let q = dispatch_get_global_queue(0, 0)
    return Promise<T> { (fulfill, reject) in
        dispatch_async(q) {
            let obj: AnyObject = body()
            if obj is NSError {
                reject(obj as! NSError)
            } else {
                fulfill(obj as! T)
            }
        }
    }
}
