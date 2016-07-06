import UIKit.UIActionSheet
#if !COCOAPODS
import PromiseKit
#endif

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
    public func promise(in view: UIView) -> Promise<Int> {
        let proxy = PMKActionSheetDelegate()
        delegate = proxy
        proxy.retainCycle = proxy
        show(in: view)

        if numberOfButtons == 1 && cancelButtonIndex == 0 {
            NSLog("PromiseKit: An action sheet is being promised with a single button that is set as the cancelButtonIndex. The promise *will* be cancelled which may result in unexpected behavior. See http://promisekit.org/PromiseKit-2.0-Released/ for cancellation documentation.")
        }

        return proxy.promise
    }

    public enum Error: CancellableError {
        case cancelled

        public var isCancelled: Bool {
            switch self {
                case .cancelled: return true
            }
        }
    }
}

private class PMKActionSheetDelegate: NSObject, UIActionSheetDelegate {
    let (promise, fulfill, reject) = Promise<Int>.pending()
    var retainCycle: NSObject?

    @objc func actionSheet(_ actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        defer { retainCycle = nil }

        if buttonIndex != actionSheet.cancelButtonIndex {
            fulfill(buttonIndex)
        } else {
            reject(UIActionSheet.Error.cancelled)
        }
    }
}
