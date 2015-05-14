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
