import Foundation
import PromiseKit

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
    public func observe<T>(keyPath: String) -> Promise<T> {
        let (promise, fulfill, reject) = Promise<T>.defer()
        KVOProxy(observee: self, keyPath: keyPath) { obj in
            if let obj = obj as? T {
                fulfill(obj)
            } else {
                let info = [NSLocalizedDescriptionKey: "The observed property was not of the requested type."]
                reject(NSError(domain: PMKErrorDomain, code: PMKInvalidUsageError, userInfo: info))
            }
        }
        return promise
    }
}

private class KVOProxy: NSObject {
    var retainCycle: KVOProxy?
    let fulfill: (AnyObject?) -> Void

    init(observee: NSObject, keyPath: String, resolve: (AnyObject?) -> Void) {
        fulfill = resolve
        super.init()
        retainCycle = self
        observee.addObserver(self, forKeyPath: keyPath, options: NSKeyValueObservingOptions.New, context: pointer)
    }

    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == pointer {
            fulfill(change[NSKeyValueChangeNewKey])
            object.removeObserver(self, forKeyPath: keyPath)
            retainCycle = nil
        }
    }

    private lazy var pointer: UnsafeMutablePointer<KVOProxy> = {
        return UnsafeMutablePointer<KVOProxy>(Unmanaged<KVOProxy>.passUnretained(self).toOpaque())
    }()
}
