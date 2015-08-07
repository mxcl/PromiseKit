import Foundation.NSError

/**
 AnyPromise is a Promise that can be used in Objective-C code

 Swift code can only convert Promises to AnyPromises or vice versa.

 Libraries that only provide promises will require you to write a
 small Swift function that can convert those promises into AnyPromises
 as you require them.

 To effectively use AnyPromise in Objective-C code you must use `#import`
 rather than `@import PromiseKit;`

     #import <PromiseKit/PromiseKit.h>
*/

/**
 Resolution.Fulfilled takes an Any. When retrieving the Any you cannot
 convert it into an AnyObject?. By giving Fulfilled an object that has
 an AnyObject? property we never have to cast and everything is fine.
*/
private class Box {
    let obj: AnyObject?
    
    init(_ obj: AnyObject?) {
        self.obj = obj
    }
}

private func box(obj: AnyObject?) -> Resolution {
    if let error = obj as? NSError {
        unconsume(error)
        return .Rejected(error)
    } else {
        return .Fulfilled(Box(obj))
    }
}

private func unbox(resolution: Resolution) -> AnyObject? {
    switch resolution {
    case .Fulfilled(let box):
        return (box as! Box).obj
    case .Rejected(let error):
        return error
    }
}


public typealias AnyPromise = PMKPromise


@objc(PMKAnyPromise) public class PMKPromise: NSObject {
    var state: State

    /**
     @return A new AnyPromise bound to a Promise<T>.

     The two promises represent the same task, any changes to either
     will instantly reflect on both.
    */
    public init<T: AnyObject>(bound: Promise<T>) {
        //WARNING copy pasta from below. FIXME how?
        var resolve: ((Resolution) -> Void)!
        state = UnsealedState(resolver: &resolve)
        bound.pipe { resolution in
            switch resolution {
            case .Fulfilled:
                resolve(box(bound.value))
            case .Rejected(let error):
                resolve(box(error))
            }
        }
    }

    public init<T: AnyObject>(bound: Promise<T?>) {
        //WARNING copy pasta from above. FIXME how?
        var resolve: ((Resolution) -> Void)!
        state = UnsealedState(resolver: &resolve)
        bound.pipe { resolution in
            switch resolution {
            case .Fulfilled:
                resolve(box(bound.value!))
            case .Rejected(let error):
                resolve(box(error))
            }
        }
    }

    /**
     @return A new AnyPromise bound to a Promise<[T]>.

     The two promises represent the same task, any changes to either
     will instantly reflect on both.
    
     The value is converted to an NSArray so Objective-C can use it.
    */
    public init<T: AnyObject>(bound: Promise<[T]>) {
        //WARNING copy pasta from above. FIXME how?
        var resolve: ((Resolution) -> Void)!
        state = UnsealedState(resolver: &resolve)
        bound.pipe { resolution in
            switch resolution {
            case .Fulfilled:
                resolve(box(NSArray(array: bound.value!)))
            case .Rejected(let error):
                resolve(box(error))
            }
        }
    }

    /**
    @return A new AnyPromise bound to a Promise<[T]>.

    The two promises represent the same task, any changes to either
    will instantly reflect on both.

    The value is converted to an NSArray so Objective-C can use it.
    */
    public init<T: AnyObject, U: AnyObject>(bound: Promise<[T:U]>) {
        //WARNING copy pasta from above. FIXME how?
        var resolve: ((Resolution) -> Void)!
        state = UnsealedState(resolver: &resolve)
        bound.pipe { resolution in
            switch resolution {
            case .Fulfilled:
                resolve(box(bound.value! as NSDictionary))
            case .Rejected(let error):
                resolve(box(error))
            }
        }
    }

    convenience public init(bound: Promise<Int>) {
        self.init(bound: bound.then(on: zalgo) { NSNumber(integer: $0) })
    }

    convenience public init(bound: Promise<Void>) {
        self.init(bound: bound.then(on: zalgo) { _ -> AnyObject? in return nil })
    }

    @objc init(@noescape bridge: ((AnyObject?) -> Void) -> Void) {
        var resolve: ((Resolution) -> Void)!
        state = UnsealedState(resolver: &resolve)
        bridge { result in
            func preresolve(obj: AnyObject?) {
                resolve(box(obj))
            }
            if let next = result as? AnyPromise {
                next.pipe(preresolve)
            } else {
                preresolve(result)
            }
        }
    }

    @objc func pipe(body: (AnyObject?) -> Void) {
        state.get { seal in
            func prebody(resolution: Resolution) {
                body(unbox(resolution))
            }
            switch seal {
            case .Pending(let handlers):
                handlers.append(prebody)
            case .Resolved(let resolution):
                prebody(resolution)
            }
        }
    }

    @objc var __value: AnyObject? {
        if let resolution = state.get() {
            return unbox(resolution)
        } else {
            return nil
        }
    }

    /**
     A promise starts pending and eventually resolves.

     @return True if the promise has not yet resolved.
    */
    @objc public var pending: Bool {
        return state.get() == nil
    }

    /**
     A promise starts pending and eventually resolves.

     @return True if the promise has resolved.
    */
    @objc public var resolved: Bool {
        return !pending
    }

    /**
     A promise starts pending and eventually resolves.
    
     A fulfilled promise is resolved and succeeded.

     @return True if the promise was fulfilled.
    */
    @objc public var fulfilled: Bool {
        switch state.get() {
        case .Some(.Fulfilled):
            return true
        default:
            return false
        }
    }

    /**
     A promise starts pending and eventually resolves.
    
     A rejected promise is resolved and failed.

     @return True if the promise was rejected.
    */
    @objc public var rejected: Bool {
        switch state.get() {
        case .Some(.Rejected):
            return true
        default:
            return false
        }
    }

    // because you can’t access top-level Swift functions in objc
    @objc class func setUnhandledErrorHandler(body: (NSError) -> Void) -> (NSError) -> Void {
        let oldHandler = PMKUnhandledErrorHandler
        PMKUnhandledErrorHandler = body
        return oldHandler
    }

    /**
     Continue a Promise<T> chain from an AnyPromise.
    */
    public func then<T>(on q: dispatch_queue_t = dispatch_get_main_queue(), body: (AnyObject?) -> T) -> Promise<T> {
        return Promise { fulfill, reject in
            pipe { object in
                if let error = object as? NSError {
                    reject(error)
                } else {
                    let value: AnyObject? = self.valueForKey("value")
                    contain_zalgo(q) {
                        fulfill(body(value))
                    }
                }
            }
        }
    }

    /**
     Continue a Promise<T> chain from an AnyPromise.
    */
    public func then(on q: dispatch_queue_t = dispatch_get_main_queue(), body: (AnyObject?) -> AnyPromise) -> Promise<AnyObject?> {
        return Promise { fulfill, reject in
            pipe { object in
                if let error = object as? NSError {
                    reject(error)
                } else {
                    contain_zalgo(q) {
                        body(object).pipe { object in
                            if let error = object as? NSError {
                                reject(error)
                            } else {
                                fulfill(object)
                            }
                        }
                    }
                }
            }
        }
    }

    /**
     Continue a Promise<T> chain from an AnyPromise.
    */
    public func then<T>(on q: dispatch_queue_t = dispatch_get_main_queue(), body: (AnyObject?) -> Promise<T>) -> Promise<T> {
        return Promise(passthru: { resolve in
            pipe { object in
                if let error = object as? NSError {
                    resolve(.Rejected(error))
                } else {
                    contain_zalgo(q) {
                        body(object).pipe(resolve)
                    }
                }
            }
        })
    }
}


extension AnyPromise: DebugPrintable {
    override public var debugDescription: String {
        return "AnyPromise: \(state)"
    }
}
