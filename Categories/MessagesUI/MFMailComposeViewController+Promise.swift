import PromiseKit
import MessageUI.MFMailComposeViewController
import UIKit.UIViewController

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
        presentViewController(vc, animated: animated, completion: completion)
        proxy.promise.finally {
            self.dismissViewControllerAnimated(animated, completion: nil)
        }
        return proxy.promise
    }
}

private class PMKMailComposeViewControllerDelegate: NSObject, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate {

    let (promise, fulfill, reject) = Promise<MFMailComposeResult>.defer()
    var retainCycle: NSObject?

    @objc func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        if error != nil {
            reject(error)
        } else {
            switch result.value {
            case MFMailComposeResultFailed.value:
                var info = [NSObject: AnyObject]()
                info[NSLocalizedDescriptionKey] = "The attempt to save or send the message was unsuccessful."
                info[NSUnderlyingErrorKey] = NSNumber(unsignedInt: result.value)
                reject(NSError(domain: PMKErrorDomain, code: PMKOperationFailed, userInfo: info))
            case MFMailComposeResultCancelled.value:
                reject(NSError.cancelledError())
            default:
                fulfill(result)
            }
        }
        retainCycle = nil
    }
}
