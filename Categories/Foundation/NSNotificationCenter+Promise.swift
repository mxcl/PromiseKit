import Foundation.NSNotification
#if !COCOAPODS
import PromiseKit
#endif

/**
 To import the `NSNotificationCenter` category:

    use_frameworks!
    pod "PromiseKit/Foundation"

 Or `NSNotificationCenter` is one of the categories imported by the umbrella pod:

    use_frameworks!
    pod "PromiseKit"

 And then in your sources:

    import PromiseKit
*/
extension NotificationCenter {
    public class func once(_ name: String) -> NotificationPromise {
        return NotificationCenter.default().once(name)
    }

    public func once(_ name: String) -> NotificationPromise {
        let (promise, fulfill) = NotificationPromise.go()
        let id = addObserver(forName: NSNotification.Name(rawValue: name), object: nil, queue: nil, using: fulfill)
        promise.then(on: zalgo) { _ in self.removeObserver(id) }
        return promise
    }
}

public class NotificationPromise: Promise<[String: Any]> {
    private let (parentPromise, parentFulfill, _) = Promise<Notification>.pendingPromise()

    public func asNotification() -> Promise<Notification> {
        return parentPromise
    }

    private class func go() -> (NotificationPromise, (Notification) -> Void) {
        var fulfill: (([String: Any]) -> Void)!
        let promise = NotificationPromise { f, _ in fulfill = f }
        promise.parentPromise.then { fulfill!($0.userInfo ?? [:]) }
        return (promise, promise.parentFulfill)
    }

    private override init(@noescape resolvers: (fulfill: ([String: Any]) -> Void, reject: (ErrorProtocol) -> Void) throws -> Void) {
        super.init(resolvers: resolvers)
    }
}
