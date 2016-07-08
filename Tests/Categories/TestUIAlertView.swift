import PromiseKit
import UIKit
import XCTest

class Test_UIAlertView_Swift: UIKitTestCase {
    // fulfills with buttonIndex
    func test1() {
        let ex = expectation(description: "")

        let alert = UIAlertView()
        alert.addButton(withTitle: "0")
        alert.addButton(withTitle: "1")
        alert.cancelButtonIndex = alert.addButton(withTitle: "2")
        alert.promise().then { x -> Void in
            XCTAssertEqual(x, 1)
            ex.fulfill()
        }
        after(interval: 0.1).then {
            alert.dismiss(withClickedButtonIndex: 1, animated: false)
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    // cancel button presses are cancelled errors
    func test2() {
        let ex = expectation(description: "")

        let alert = UIAlertView()
        alert.addButton(withTitle: "0")
        alert.addButton(withTitle: "1")
        alert.cancelButtonIndex = alert.addButton(withTitle: "2")
        alert.promise().catch(policy: .allErrors) { err in
            guard let err = err as? UIAlertView.Error else { return XCTFail() }
            XCTAssertTrue(err == .cancelled)
            XCTAssertTrue(err.isCancelled)
            ex.fulfill()
        }
        after(interval: 0.1).then {
            alert.dismiss(withClickedButtonIndex: 2, animated: false)
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    // single button UIAlertViews don't get considered cancelled
    func test3() {
        let ex = expectation(description: "")

        let alert = UIAlertView()
        alert.addButton(withTitle: "0")
        alert.promise().then { _ in
            ex.fulfill()
        }
        after(interval: 0.1).then {
            alert.dismiss(withClickedButtonIndex: 0, animated: false)
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    // single button UIAlertViews don't get considered cancelled unless the cancelIndex is set
    func test4() {
        let ex = expectation(description: "")

        let alert = UIAlertView()
        alert.cancelButtonIndex = alert.addButton(withTitle: "0")
        alert.promise().catch(policy: .allErrors) { _ in
            ex.fulfill()
        }
        after(interval: 0.1).then {
            alert.dismiss(withClickedButtonIndex: 0, animated: false)
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
}
