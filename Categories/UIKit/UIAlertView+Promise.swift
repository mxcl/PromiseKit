import Foundation
import PromiseKit
import UIKit.UIAlertView

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
extension UIAlertView {
    public func promise() -> Promise<Int> {
        let proxy = PMKAlertViewDelegate()
        delegate = proxy
        proxy.retainCycle = proxy
        show()
        return proxy.promise
    }
}

private class PMKAlertViewDelegate: NSObject, UIAlertViewDelegate {
    let (promise, fulfill, reject) = Promise<Int>.defer()
    var retainCycle: NSObject?

    @objc func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        if buttonIndex != alertView.cancelButtonIndex {
            fulfill(buttonIndex)
        } else {
            reject(NSError.cancelledError())
        }
    }
}
