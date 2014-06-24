import UIKit

class UIAlertViewProxy: NSObject, UIAlertViewDelegate {
    let fulfiller: (Int) -> Void

    init(fulfiller: (Int) -> Void) {
        self.fulfiller = fulfiller
        super.init()
        PMKRetain(self)
    }

    func alertView(alertView: UIAlertView!, didDismissWithButtonIndex buttonIndex: Int) {
        fulfiller(buttonIndex)
        PMKRelease(self)
    }
}


extension UIAlertView {
    func promise() -> Promise<Int> {
        let deferred = Promise<Int>.defer()
        delegate = UIAlertViewProxy(deferred.fulfiller)
        show()
        return deferred.promise
    }
}
