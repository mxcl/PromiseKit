import Foundation.NSError

@objc(AnyPromise) public class AnyPromise: NSObject {

    private var state: State

    /**
     - Returns: A new AnyPromise bound to a Promise<T?>.
     The two promises represent the same task, any changes to either will instantly reflect on both.
    */
    public init<T: AnyObject>(bound: Promise<T?>) {
        var resolve: ((AnyObject?) -> Void)!
        state = State(resolver: &resolve)
        bound.pipe { resolution in
            switch resolution {
            case .fulfilled(let value):
                resolve(value)
            case .rejected(let error, let token):
                let nserror = error as NSError
                unconsume(error: nserror, reusingToken: token)
                resolve(nserror)
            }
        }
    }

    /**
     - Returns: A new AnyPromise bound to a Promise<T>.
     The two promises represent the same task, any changes to either will instantly reflect on both.
    */
    convenience public init<T: AnyObject>(bound: Promise<T>) {
        // FIXME efficiency. Allocating the extra promise for conversion sucks.
        self.init(bound: bound.then(on: zalgo){ Optional.some($0) })
    }

    /**
     - Returns: A new `AnyPromise` bound to a `Promise<[T]>`.
     The two promises represent the same task, any changes to either will instantly reflect on both.
     The value is converted to an NSArray so Objective-C can use it.
    */
    convenience public init<T: AnyObject>(bound: Promise<[T]>) {
        self.init(bound: bound.then(on: zalgo) { NSArray(array: $0) })
    }

    /**
     - Returns: A new AnyPromise bound to a `Promise<[T:U]>`.
     The two promises represent the same task, any changes to either will instantly reflect on both.
     The value is converted to an NSDictionary so Objective-C can use it.
    */
    convenience public init<T: AnyObject, U: AnyObject>(bound: Promise<[T:U]>) {
        self.init(bound: bound.then(on: zalgo) { $0 as NSDictionary })
    }

    /**
     - Returns: A new AnyPromise bound to a `Promise<String>`.
     The two promises represent the same task, any changes to either will instantly reflect on both.
     The value is converted to an NSString so Objective-C can use it.
     */
    convenience public init(bound: Promise<String>) {
        self.init(bound: bound.then(on: zalgo) { NSString(string: $0) })
    }

    /**
     - Returns: A new AnyPromise bound to a `Promise<Int>`.
     The two promises represent the same task, any changes to either will instantly reflect on both.
     The value is converted to an NSNumber so Objective-C can use it.
    */
    convenience public init(bound: Promise<Int>) {
        self.init(bound: bound.then(on: zalgo) { NSNumber(value: $0) })
    }

    /**
     - Returns: A new AnyPromise bound to a `Promise<Bool>`.
     The two promises represent the same task, any changes to either will instantly reflect on both.
     The value is converted to an NSNumber so Objective-C can use it.
     */
    convenience public init(bound: Promise<Bool>) {
        self.init(bound: bound.then(on: zalgo) { NSNumber(value: $0) })
    }

    /**
     - Returns: A new AnyPromise bound to a `Promise<Void>`.
     The two promises represent the same task, any changes to either will instantly reflect on both.
    */
    convenience public init(bound: Promise<Void>) {
        self.init(bound: bound.then(on: zalgo) { Optional<AnyObject>.none })
    }

    @objc init(bridge: @noescape ((AnyObject?) -> Void) -> Void) {
        var resolve: ((AnyObject?) -> Void)!
        state = State(resolver: &resolve)
        bridge { result in
            if let next = result as? AnyPromise {
                next.pipe(resolve)
            } else {
                resolve(result)
            }
        }
    }

    @objc func pipe(_ body: (AnyObject?) -> Void) {
        state.get { seal in
            switch seal {
            case .pending(let handlers):
                handlers.append(body: body)
            case .resolved(let value):
                body(value)
            }
        }
    }

    @objc var __value: AnyObject? {
        return state.get() ?? nil
    }

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
     A fulfilled promise has resolved successfully.
     - Returns: `true` if the promise was fulfilled.
    */
    @objc public var fulfilled: Bool {
        switch state.get() {
        case .some(let obj) where obj is NSError:
            return false
        case .some:
            return true
        case .none:
            return false
        }
    }

    /**
     A rejected promise has resolved without success.
     - Returns: `true` if the promise was rejected.
    */
    @objc public var rejected: Bool {
        switch state.get() {
        case .some(let obj) where obj is NSError:
            return true
        default:
            return false
        }
    }

    /**
     Continue a Promise<T> chain from an AnyPromise.
    */
    public func then<T>(on q: dispatch_queue_t = PMKDefaultDispatchQueue()!, body: (AnyObject?) throws -> T) -> Promise<T> {
        return Promise(sealant: { resolve in
            pipe { object in
                if let error = object as? NSError {
                    resolve(.rejected(error, error.token))
                } else {
                    contain_zalgo(q, rejecter: resolve) {
                        resolve(.fulfilled(try body(self.value(forKey: "value"))))
                    }
                }
            }
        })
    }

    /**
     Continue a Promise<T> chain from an AnyPromise.
    */
    public func then(on q: dispatch_queue_t = PMKDefaultDispatchQueue()!, body: (AnyObject?) -> AnyPromise) -> Promise<AnyObject?> {
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
    public func then<T>(on q: dispatch_queue_t = PMKDefaultDispatchQueue()!, body: (AnyObject?) -> Promise<T>) -> Promise<T> {
        return Promise(sealant: { resolve in
            pipe { object in
                if let error = object as? NSError {
                    resolve(.rejected(error, error.token))
                } else {
                    contain_zalgo(q) {
                        body(object).pipe(body: resolve)
                    }
                }
            }
        })
    }

    private class State: UnsealedState<AnyObject?> {
        required init(resolver: inout ((AnyObject?) -> Void)!) {
            var preresolve: ((AnyObject?) -> Void)!
            super.init(resolver: &preresolve)
            resolver = { obj in
                if let error = obj as? NSError { unconsume(error: error) }
                preresolve(obj)
            }
        }
    }
}


extension AnyPromise {
    override public var description: String {
        return "AnyPromise: \(state)"
    }
}
