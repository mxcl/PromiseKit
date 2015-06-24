import MessageUI
import PromiseKit
import UIKit
import XCTest

class TestPromiseMailComposer: UIKitTestCase {

    // cancelling mail composer cancels promise
    func test7() {
        let ex1 = expectationWithDescription("")
        let ex2 = expectationWithDescription("")
        var order = false

        let mailer = MFMailComposeViewController()
        let promise = rootvc.promiseViewController(mailer, animated: false, completion: {
            after(0.25).then { _ -> Void in
                XCTAssertFalse(order)
                let button = mailer.viewControllers[0].navigationItem.leftBarButtonItem!
                UIControl().sendAction(button.action, to: button.target, forEvent: nil)
                ex1.fulfill()
            }
        })
        promise.report { _ -> Void in
            XCTFail()
        }
        promise.report(policy: .AllErrors) { _ -> Void in
            // seems necessary to give vc stack a bit of time
            after(0.5).then(ex2.fulfill)
            order = true
        }
        waitForExpectationsWithTimeout(10, handler: nil)

        XCTAssertNil(rootvc.presentedViewController)
    }
}
