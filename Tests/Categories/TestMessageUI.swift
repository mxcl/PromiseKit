import MessageUI
import PromiseKit
import UIKit
import XCTest

class TestPromiseMailComposer: UIKitTestCase {

    // cancelling mail composer cancels promise
    func test7() {
        let ex = expectationWithDescription("")
        let mailer = MFMailComposeViewController()
        let promise = rootvc.promiseViewController(mailer, animated: false, completion: {
            after(0.05).then { _ -> Void in
                let button = mailer.viewControllers[0].navigationItem.leftBarButtonItem!

                let control: UIControl = UIControl()
                control.sendAction(button.action, to: button.target, forEvent: nil)
            }
        })
        promise.catch_ { _ -> Void in
            XCTFail()
        }
        promise.catch_(policy: CatchPolicy.AllErrors) { _ -> Void in
            // seems necessary to give vc stack a bit of time
            after(0.5).then(ex.fulfill)
        }
        waitForExpectationsWithTimeout(10, handler: nil)

        XCTAssertNil(rootvc.presentedViewController)
    }
}
