import Social.SLComposeViewController
import UIKit.UIViewController
#if !COCOAPODS
import PromiseKit
#endif

/**
 To import this `UIViewController` category:

    use_frameworks!
    pod "PromiseKit/Social"

 And then in your sources:

    import PromiseKit
*/
extension UIViewController {
    public func promiseViewController(_ vc: SLComposeViewController, animated: Bool = true, completion: (() -> Void)? = nil) -> Promise<Void> {
        present(vc, animated: animated, completion: completion)
        return Promise { fulfill, reject in
            vc.completionHandler = { result in
                if result == .cancelled {
                    reject(SLComposeViewController.Error.cancelled)
                } else {
                    fulfill()
                }
            }
        }
    }
}

extension SLComposeViewController {
    public enum Error: CancellableError {
        case cancelled

        public var isCancelled: Bool {
            switch self { case .cancelled: return true }
        }
    }
}
