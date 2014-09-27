import Foundation
import UIKit

//TODO use plain T, once Swift compiler is more mature
//TODO nest in Promise class (currently causes SourceKit to freak out)
enum State<T> {
    case Pending
    case Fulfilled(@autoclosure () -> T)
    case Rejected(NSError)
}


private func bind1<T, U>(body:(T) -> Promise<U>, value:T, fulfiller: (U)->(), rejecter: (NSError)->()) {
    let promise = body(value)
    switch promise.state {
    case .Rejected(let error):
        rejecter(error)
    case .Fulfilled(let value):
        fulfiller(value())
    case .Pending:
        promise.handlers.append{
            switch promise.state {
            case .Rejected(let error):
                rejecter(error)
            case .Fulfilled(let value):
                fulfiller(value())
            case .Pending:
                abort()
            }
        }
    }
}

private func bind2<T>(body:(NSError) -> Promise<T>, error: NSError, fulfiller: (T)->(), rejecter: (NSError)->()) {
    let promise = body(error)
    switch promise.state {
    case .Rejected(let error):
        rejecter(error)
    case .Fulfilled(let value):
        fulfiller(value())
    case .Pending:
        promise.handlers.append{
            switch promise.state {
            case .Rejected(let error):
                rejecter(error)
            case .Fulfilled(let value):
                fulfiller(value())
            case .Pending:
                abort()
            }
        }
    }
}




func dispatch_promise<T>(to queue:dispatch_queue_t = dispatch_get_global_queue(0, 0), block:(fulfill: (T)->Void, reject: (NSError)->Void) -> ()) -> Promise<T> {
    return Promise<T> { (fulfiller, rejecter) in
        dispatch_async(queue) {
            block(fulfiller, rejecter)
        }
    }
}

func dispatch_main(block: ()->()) {
    dispatch_async(dispatch_get_main_queue(), block)
}

func dispatch_bg<T>(body:() -> AnyObject) -> Promise<T> {
    return dispatch_promise(to: dispatch_get_global_queue(0, 0)) { d in
        let obj: AnyObject = body()
        if obj is NSError {
            d.reject(obj as NSError)
        } else {
            d.fulfill(obj as T)
        }
    }
}


public class Promise<T> {
    var handlers:[()->()] = []
    var state:State<T> = .Pending

    public var rejected:Bool {
        switch state {
            case .Fulfilled, .Pending: return false
            case .Rejected: return true
        }
    }
    public var fulfilled:Bool {
        switch state {
            case .Rejected, .Pending: return false
            case .Fulfilled: return true
        }
    }
    public var pending:Bool {
        switch state {
            case .Rejected, .Fulfilled: return false
            case .Pending: return true
        }
    }

    /**
      returns the fulfilled value unless the Promise is pending
      or rejected in which case returns `nil`
     */
    public var value:T? {
        switch state {
        case .Fulfilled(let value):
            return value()
        default:
            return nil
        }
    }

    /**
      returns the rejected error unless the Promise is pending
      or fulfilled in which case returns `nil`
    */
    public var error:NSError? {
        switch state {
        case .Rejected(let error):
            return error
        default:
            return nil
        }
    }

    // TODO move into init as has no use anywhere else
    // is here currently because: beta 6 compile errors it
    private func recurse() {
        for handler in handlers { handler() }
        handlers.removeAll(keepCapacity: false)
    }

    public init(_ body:(fulfill:(T) -> Void, reject:(NSError) -> Void) -> Void) {
        func rejecter(err: NSError) {
            if pending {
                state = .Rejected(err)
                recurse()
            }
        }
        func fulfiller(obj: T) {
            if pending {
                state = .Fulfilled(obj)
                recurse()
            }
        }
        body(fulfiller, rejecter)
    }

    public class func defer() -> (promise:Promise, fulfiller:(T) -> Void, rejecter:(NSError) -> Void) {
        var f: ((T) -> Void)?
        var r: ((NSError) -> Void)?
        let p = Promise{ f = $0; r = $1 }
        return (p, f!, r!)
    }

    public init(value:T) {
        self.state = .Fulfilled(value)
    }

    public init(error:NSError) {
        self.state = .Rejected(error)
    }

    public func then<U>(onQueue q:dispatch_queue_t = dispatch_get_main_queue(), body:(T) -> U) -> Promise<U> {
        switch state {
        case .Rejected(let error):
            return Promise<U>(error: error)
        case .Fulfilled(let value):
            return dispatch_promise(to:q){ d in d.fulfill(body(value())) }
        case .Pending:
            return Promise<U>{ (fulfiller, rejecter) in
                self.handlers.append {
                    switch self.state {
                    case .Rejected(let error):
                        rejecter(error)
                    case .Fulfilled(let value):
                        dispatch_async(q) {
                            fulfiller(body(value()))
                        }
                    case .Pending:
                        abort()
                    }
                }
            }
        }
    }

    public func then<U>(onQueue q:dispatch_queue_t = dispatch_get_main_queue(), body:(T) -> Promise<U>) -> Promise<U> {

        switch state {
        case .Rejected(let error):
            return Promise<U>(error: error)
        case .Fulfilled(let value):
            return dispatch_promise(to:q){
                bind1(body, value(), $0, $1)
            }
        case .Pending:
            return Promise<U>{ (fulfiller, rejecter) in
                self.handlers.append{
                    switch self.state {
                    case .Pending:
                        abort()
                    case .Fulfilled(let value):
                        dispatch_async(q){
                            bind1(body, value(), fulfiller, rejecter)
                        }
                    case .Rejected(let error):
                        rejecter(error)
                    }
                }
            }
        }
    }

    public func catch(onQueue:dispatch_queue_t = dispatch_get_main_queue(), body:(NSError) -> T) -> Promise<T> {
        switch state {
        case .Fulfilled(let value):
            return Promise(value: value())
        case .Rejected(let error):
            return dispatch_promise(to:onQueue){ (fulfiller, _) -> Void in fulfiller(body(error)) }
        case .Pending:
            return Promise{ (fulfiller, rejecter) in
                self.handlers.append {
                    switch self.state {
                    case .Fulfilled(let value):
                        fulfiller(value())
                    case .Rejected(let error):
                        dispatch_async(onQueue){ fulfiller(body(error)) }
                    case .Pending:
                        abort()
                    }
                }
            }
        }
    }

    public func catch(onQueue:dispatch_queue_t = dispatch_get_main_queue(), body:(NSError) -> Void) -> Void {
        switch state {
        case .Rejected(let error):
            dispatch_async(onQueue, {
                body(error)
            })
        case .Fulfilled:
            let noop = 0
        case .Pending:
            self.handlers.append({
                switch self.state {
                case .Rejected(let error):
                    dispatch_async(onQueue){ body(error) }
                case .Fulfilled:
                    let noop = 0
                case .Pending:
                    abort()
                }
            })
        }
    }

    public func catch(onQueue q:dispatch_queue_t = dispatch_get_main_queue(), body:(NSError) -> Promise<T>) -> Promise<T>
    {
        switch state {
        case .Rejected(let error):
            return dispatch_promise(to:q){
                bind2(body, error, $0, $1)
            }
        case .Fulfilled(let value):
            return Promise(value:value())
            
        case .Pending:
            return Promise{ (fulfiller, rejecter) in
                self.handlers.append{
                    switch self.state {
                    case .Pending:
                        abort()
                    case .Fulfilled(let value):
                        fulfiller(value())
                    case .Rejected(let error):
                        dispatch_async(q){
                            bind2(body, error, fulfiller, rejecter)
                        }
                    }
                }
            }
        }
    }

    public func finally(body:() -> Void) -> Promise<T> {
        let q = dispatch_get_main_queue()
        return dispatch_promise(to:q) { (fulfiller, rejecter) in
            switch self.state {
            case .Fulfilled(let value):
                body()
                fulfiller(value())
            case .Rejected(let error):
                body()
                rejecter(error)
            case .Pending:
                self.handlers.append{
                    body()
                    switch self.state {
                    case .Fulfilled(let value):
                        fulfiller(value())
                    case .Rejected(let error):
                        rejecter(error)
                    case .Pending:
                        abort()
                    }
                }
            }
        }
    }
}
