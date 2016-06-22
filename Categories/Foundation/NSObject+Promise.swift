import Foundation
#if !COCOAPODS
import PromiseKit
#endif

/**
 To import the `NSObject` category:

    use_frameworks!
    pod "PromiseKit/Foundation"

 Or `NSObject` is one of the categories imported by the umbrella pod:

    use_frameworks!
    pod "PromiseKit"
 
 And then in your sources:

    import PromiseKit
*/
extension NSObject {
    /**
      @return A promise that resolves when the provided keyPath changes.

      @warning *Important* The promise must not outlive the object under observation.

      @see Apple’s KVO documentation.
    */
    public func observe<T>(_ keyPath: String) -> Promise<T> {
        let (promise, fulfill, reject) = Promise<T>.pendingPromise()
        let proxy = KVOProxy(observee: self, keyPath: keyPath) { obj in
            if let obj = obj as? T {
                fulfill(obj)
            } else {
                let info = [NSLocalizedDescriptionKey: "The observed property was not of the requested type."]
                reject(NSError(domain: PMKErrorDomain, code: PMKInvalidUsageError, userInfo: info))
            }
        }
        proxy.retainCycle = proxy
        return promise
    }
}

private class KVOProxy: NSObject {
    var retainCycle: KVOProxy?
    let fulfill: (AnyObject?) -> Void

    init(observee: NSObject, keyPath: String, resolve: (AnyObject?) -> Void) {
        fulfill = resolve
        super.init()
        observee.addObserver(self, forKeyPath: keyPath, options: NSKeyValueObservingOptions.new, context: pointer)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: AnyObject?, change: [NSKeyValueChangeKey : AnyObject]?, context: UnsafeMutablePointer<Void>?) {
        if let change = change where context == pointer {
            defer { retainCycle = nil }
            fulfill(change[NSKeyValueChangeKey.newKey])
            if let object = object, keyPath = keyPath {
                object.removeObserver(self, forKeyPath: keyPath)
            }
        }
    }

    private lazy var pointer: UnsafeMutablePointer<Void> = {
        return UnsafeMutablePointer<Void>(OpaquePointer(bitPattern: Unmanaged<KVOProxy>.passUnretained(self)))
    }()
}
