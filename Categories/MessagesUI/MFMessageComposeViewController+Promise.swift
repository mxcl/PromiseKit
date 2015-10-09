import Foundation
import MessageUI.MFMessageComposeViewController
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
    public func promiseViewController(vc: MFMessageComposeViewController, animated: Bool = true, completion:(() -> Void)? = nil) -> Promise<Void> {
        let proxy = PMKMessageComposeViewControllerDelegate()
        proxy.retainCycle = proxy
        vc.messageComposeDelegate = proxy
        presentViewController(vc, animated: animated, completion: completion)
        proxy.promise.always {
            vc.dismissViewControllerAnimated(animated, completion: nil)
        }
        return proxy.promise
    }
}

extension MFMessageComposeViewController {
    public enum Error: ErrorType {
        case Cancelled
    }
}

private class PMKMessageComposeViewControllerDelegate: NSObject, MFMessageComposeViewControllerDelegate, UINavigationControllerDelegate {

    let (promise, fulfill, reject) = Promise<Void>.pendingPromise()
    var retainCycle: NSObject?

    @objc func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        defer { retainCycle = nil }

        switch result.rawValue {
        case MessageComposeResultSent.rawValue:
            fulfill()
        case MessageComposeResultFailed.rawValue:
            var info = [NSObject: AnyObject]()
            info[NSLocalizedDescriptionKey] = "The attempt to save or send the message was unsuccessful."
            info[NSUnderlyingErrorKey] = NSNumber(unsignedInt: result.rawValue)
            reject(NSError(domain: PMKErrorDomain, code: PMKOperationFailed, userInfo: info))
        case MessageComposeResultCancelled.rawValue:
            reject(MFMessageComposeViewController.Error.Cancelled)
        default:
            fatalError("Swift Sucks")
        }
    }
}

public enum MessageUIError: ErrorType {
    case Failed
}