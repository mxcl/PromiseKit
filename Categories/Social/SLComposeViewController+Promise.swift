import PromiseKit
import Social.SLComposeViewController
import UIKit.UIViewController

/**
 To import this `UIViewController` category:

    use_frameworks!
    pod "PromiseKit/Social"

 And then in your sources:

    import PromiseKit
*/
extension UIViewController {
    public func promiseViewController(vc: SLComposeViewController, animated: Bool = true, completion: (() -> Void)? = nil) -> Promise<Void> {
        presentViewController(vc, animated: animated, completion: completion)
        return Promise { fulfill, reject in
            vc.completionHandler = { result in
                if result == .Cancelled {
                    reject(NSError.cancelledError())
                } else {
                    fulfill()
                }
            }
        }
    }

}
