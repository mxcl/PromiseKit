import Foundation
#if !PMKCocoaPods
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
    /// Observe the named notification once
    public func observe(once name: Notification.Name, object: Any? = nil) -> Guarantee<Notification> {
        let (promise, fulfill) = Guarantee<Notification>.pending()
      #if os(Linux) && ((swift(>=4.0) && !swift(>=4.0.1)) || (swift(>=3.0) && !swift(>=3.2.1)))
        let id = addObserver(forName: name, object: object, queue: nil, usingBlock: fulfill)
      #else
        let id = addObserver(forName: name, object: object, queue: nil, using: fulfill)
      #endif
        promise.done { _ in self.removeObserver(id) }
        return promise
    }
}
