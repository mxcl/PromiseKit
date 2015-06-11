import PromiseKit
import UIKit.UIActionSheet

/**
 To import the `UIActionSheet` category:

    use_frameworks!
    pod "PromiseKit/UIKit"

 Or `UIKit` is one of the categories imported by the umbrella pod:

    use_frameworks!
    pod "PromiseKit"

 And then in your sources:

    import PromiseKit
*/
extension UIActionSheet {
    public func promiseInView(view: UIView) -> Promise<Int> {
        let proxy = PMKActionSheetDelegate()
        delegate = proxy
        proxy.retainCycle = proxy
        showInView(view)

        if numberOfButtons == 1 && cancelButtonIndex == 0 {
            NSLog("PromiseKit: An action sheet is being promised with a single button that is set as the cancelButtonIndex. The promise *will* be cancelled which may result in unexpected behavior. See http://promisekit.org/PromiseKit-2.0-Released/ for cancellation documentation.")
        }

        return proxy.promise
    }
}

private class PMKActionSheetDelegate: NSObject, UIActionSheetDelegate {
    let (promise, fulfill, reject) = Promise<Int>.defer()
    var retainCycle: NSObject?

    @objc func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        if buttonIndex != actionSheet.cancelButtonIndex {
            fulfill(buttonIndex)
        } else {
            reject(NSError.cancelledError())
        }
        retainCycle = nil
    }
}
