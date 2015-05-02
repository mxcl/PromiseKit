import Foundation
import MessageUI.MFMessageComposeViewController
import PromiseKit
import UIKit.UIViewController

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
        proxy.promise.finally {
            vc.dismissViewControllerAnimated(animated, completion: nil)
        }
        return proxy.promise
    }
}

private class PMKMessageComposeViewControllerDelegate: NSObject, MFMessageComposeViewControllerDelegate, UINavigationControllerDelegate {

    let (promise, fulfill, reject) = Promise<Void>.defer()
    var retainCycle: NSObject?

    @objc func messageComposeViewController(controller: MFMessageComposeViewController!, didFinishWithResult result: MessageComposeResult) {

        switch result.value {
        case MessageComposeResultSent.value:
            fulfill()
        case MessageComposeResultFailed.value:
            var info = [NSObject: AnyObject]()
            info[NSLocalizedDescriptionKey] = "The attempt to save or send the message was unsuccessful."
            info[NSUnderlyingErrorKey] = NSNumber(unsignedInt: result.value)
            reject(NSError(domain: PMKErrorDomain, code: PMKOperationFailed, userInfo: info))
        case MessageComposeResultCancelled.value:
            reject(NSError.cancelledError())
        default:
            fatalError("Swift Sucks")
        }

        retainCycle = nil
    }
}
