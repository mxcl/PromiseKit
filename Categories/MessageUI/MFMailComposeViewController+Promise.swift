import MessageUI.MFMailComposeViewController
import UIKit.UIViewController
#if !COCOAPODS
import PromiseKit
#endif

/**
 To import this `UIViewController` category:

    use_frameworks!
    pod "PromiseKit/MessageUI"

 And then in your sources:

    import PromiseKit
*/
extension UIViewController {
    public func promiseViewController(vc: MFMailComposeViewController, animated: Bool = true, completion:(() -> Void)? = nil) -> Promise<MFMailComposeResult> {
        let proxy = PMKMailComposeViewControllerDelegate()
        proxy.retainCycle = proxy
        vc.mailComposeDelegate = proxy
        present(vc, animated: animated, completion: completion)
        proxy.promise.always {
            self.dismiss(animated: animated, completion: nil)
        }
        return proxy.promise
    }
}

extension MFMailComposeViewController {
    public enum Error: CancellableErrorType {
        case Cancelled

        public var cancelled: Bool {
            switch self {
                case .Cancelled: return true
            }
        }
    }
}

private class PMKMailComposeViewControllerDelegate: NSObject, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate {

    let (promise, fulfill, reject) = Promise<MFMailComposeResult>.pendingPromise()
    var retainCycle: NSObject?

    @objc func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        defer { retainCycle = nil }

        if let error = error {
            reject(error)
        } else {
            switch result {
            case .failed:
                var info = [NSObject: AnyObject]()
                info[NSLocalizedDescriptionKey] = "The attempt to save or send the message was unsuccessful."
                info[NSUnderlyingErrorKey] = NSNumber(value: result.rawValue)
                reject(NSError(domain: PMKErrorDomain, code: PMKOperationFailed, userInfo: info))
            case .cancelled:
                reject(MFMailComposeViewController.Error.Cancelled)
            default:
                fulfill(result)
            }
        }
    }
}
