import PromiseKit
import UIKit
import XCTest

class Test_UIActionSheet_Swift: UIKitTestCase {
    // fulfills with buttonIndex
    func test1() {
        let ex = expectationWithDescription("")

        let sheet = UIActionSheet()
        sheet.addButtonWithTitle("0")
        sheet.addButtonWithTitle("1")
        sheet.cancelButtonIndex = sheet.addButtonWithTitle("2")
        sheet.promiseInView(rootvc.view).then { x -> Void in
            XCTAssertEqual(x, 1)
            ex.fulfill()
        }
        after(0.5).then {
            sheet.dismissWithClickedButtonIndex(1, animated: false)
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    // cancel button presses are cancelled errors
    func test2() {
        let ex = expectationWithDescription("")

        let sheet = UIActionSheet()
        sheet.addButtonWithTitle("0")
        sheet.addButtonWithTitle("1")
        sheet.cancelButtonIndex = sheet.addButtonWithTitle("2")
        sheet.promiseInView(rootvc.view).error(policy: .AllErrors) { err in
            guard let err = err as? UIActionSheet.Error else { return XCTFail() }
            XCTAssertTrue(err == UIActionSheet.Error.Cancelled)
            XCTAssertTrue(err.cancelled)
            ex.fulfill()
        }
        after(0.5).then {
            sheet.dismissWithClickedButtonIndex(2, animated: false)
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    // single button UIActionSheets don't get considered cancelled
    func test3() {
        let ex = expectationWithDescription("")

        let sheet = UIActionSheet()
        sheet.addButtonWithTitle("0")
        sheet.promiseInView(rootvc.view).then { _ in
            ex.fulfill()
        }
        after(0.5).then {
            sheet.dismissWithClickedButtonIndex(0, animated: false)
        }
        waitForExpectationsWithTimeout(3, handler: nil)
    }

    // single button UIActionSheets don't get considered cancelled unless the cancelIndex is set
    func test4() {
        let ex = expectationWithDescription("")

        let sheet = UIActionSheet()
        sheet.cancelButtonIndex = sheet.addButtonWithTitle("0")
        sheet.promiseInView(rootvc.view).error(policy: .AllErrors) { _ in
            ex.fulfill()
        }
        after(0.5).then {
            sheet.dismissWithClickedButtonIndex(0, animated: false)
        }
        waitForExpectationsWithTimeout(3, handler: nil)
    }
}
