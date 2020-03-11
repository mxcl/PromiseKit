import Foundation

/**
 __AnyPromise is an implementation detail.

 Because of how ObjC/Swift compatibility work we have to compose our AnyPromise
 with this internal object, however this is still part of the public interface.
 Sadly. Please don’t use it.
*/
@objc(__AnyPromise) public class __AnyPromise: NSObject {
    fileprivate let box: Box<Any?>

    @objc public init(resolver body: (@escaping (Any?) -> Void) -> Void) {
        box = EmptyBox<Any?>()
        super.init()
        body {
            if let p = $0 as? AnyPromise {
                p.d.__pipe(self.box.seal)
            } else {
                self.box.seal($0)
            }
        }
    }

    @objc public func __thenOn(_ q: DispatchQueue, execute: @escaping (Any?) -> Any?) -> AnyPromise {
        return AnyPromise(__D: __AnyPromise(resolver: { resolve in
            self.__pipe { obj in
                if !(obj is NSError) {
                    q.async {
                        resolve(execute(obj))
                    }
                } else {
                    resolve(obj)
                }
            }
        }))
    }

    @objc public func __catchOn(_ q: DispatchQueue, execute: @escaping (Any?) -> Any?) -> AnyPromise {
        return AnyPromise(__D: __AnyPromise(resolver: { resolve in
            self.__pipe { obj in
                if obj is NSError {
                    q.async {
                        resolve(execute(obj))
                    }
                } else {
                    resolve(obj)
                }
            }
        }))
    }

    @objc public func __ensureOn(_ q: DispatchQueue, execute: @escaping () -> Void) -> AnyPromise {
        return AnyPromise(__D: __AnyPromise(resolver: { resolve in
            self.__pipe { obj in
                q.async {
                    execute()
                    resolve(obj)
                }
            }
        }))
    }

    @objc public func __wait() -> Any? {
        if Thread.isMainThread {
            conf.logHandler(.waitOnMainThread)
        }
        
        var result = __value
        
        if result == nil {
            let group = DispatchGroup()
            group.enter()
            self.__pipe { obj in
                result = obj
                group.leave()
            }
            group.wait()
        }
        
        return result
    }
 
    /// Internal, do not use! Some behaviors undefined.
    @objc public func __pipe(_ to: @escaping (Any?) -> Void) {
        let to = { (obj: Any?) -> Void in
            if obj is NSError {
                to(obj)  // or we cannot determine if objects are errors in objc land
            } else {
                to(obj)
            }
        }
        switch box.inspect() {
        case .pending:
            box.inspect {
                switch $0 {
                case .pending(let handlers):
                    handlers.append { obj in
                        to(obj)
                    }
                case .resolved(let obj):
                    to(obj)
                }
            }
        case .resolved(let obj):
            to(obj)
        }
    }

    @objc public var __value: Any? {
        switch box.inspect() {
        case .resolved(let obj):
            return obj
        default:
            return nil
        }
    }

    @objc public var __pending: Bool {
        switch box.inspect() {
        case .pending:
            return true
        case .resolved:
            return false
        }
    }
}

extension AnyPromise: Thenable, CatchMixin {

    /// - Returns: A new `AnyPromise` bound to a `Promise<Any>`.
    public convenience init<U: Thenable>(_ bridge: U) {
        self.init(__D: __AnyPromise(resolver: { resolve in
            bridge.pipe {
                switch $0 {
                case .rejected(let error):
                    resolve(error as NSError)
                case .fulfilled(let value):
                    resolve(value)
                }
            }
        }))
    }

    public func pipe(to body: @escaping (Result<Any?>) -> Void) {

        func fulfill() {
            // calling through to the ObjC `value` property unwraps (any) PMKManifold
            // and considering this is the Swift pipe; we want that.
            body(.fulfilled(self.value(forKey: "value")))
        }

        switch box.inspect() {
        case .pending:
            box.inspect {
                switch $0 {
                case .pending(let handlers):
                    handlers.append {
                        if let error = $0 as? Error {
                            body(.rejected(error))
                        } else {
                            fulfill()
                        }
                    }
                case .resolved(let error as Error):
                    body(.rejected(error))
                case .resolved:
                    fulfill()
                }
            }
        case .resolved(let error as Error):
            body(.rejected(error))
        case .resolved:
            fulfill()
        }
    }

    fileprivate var d: __AnyPromise {
        return value(forKey: "__d") as! __AnyPromise
    }

    var box: Box<Any?> {
        return d.box
    }

    public var result: Result<Any?>? {
        guard let value = __value else {
            return nil
        }
        if let error = value as? Error {
            return .rejected(error)
        } else {
            return .fulfilled(value)
        }
    }

    public typealias T = Any?
}


#if swift(>=3.1)
public extension Promise where T == Any? {
    convenience init(_ anyPromise: AnyPromise) {
        self.init {
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
