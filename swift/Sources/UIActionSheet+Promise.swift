import UIKit

class UIActionSheetProxy: NSObject, UIActionSheetDelegate {
    let fulfiller: (Int) -> Void

    init(fulfiller: (Int) -> Void) {
        self.fulfiller = fulfiller
        super.init()
        PMKRetain(self)
    }

    func actionSheet(actionSheet: UIActionSheet!, didDismissWithButtonIndex buttonIndex: Int) {
        fulfiller(buttonIndex)
        PMKRelease(self)
    }
}


extension UIActionSheet {
    func promiseInView(view:UIView) -> Promise<Int> {
        let deferred = Promise<Int>.defer()
        delegate = UIActionSheetProxy(deferred.fulfiller)
        showInView(view)
        return deferred.promise
    }
}
