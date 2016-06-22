import PromiseKit
import UIKit
import XCTest

class Test_UIActionSheet_Swift: UIKitTestCase {
    // fulfills with buttonIndex
    func test1() {
        let ex = expectation(withDescription: "")

        let sheet = UIActionSheet()
        sheet.addButton(withTitle: "0")
        sheet.addButton(withTitle: "1")
        sheet.cancelButtonIndex = sheet.addButton(withTitle: "2")
        sheet.promise(in: rootvc.view).then { x -> Void in
            XCTAssertEqual(x, 1)
            ex.fulfill()
        }
        after(0.5).then {
            sheet.dismiss(withClickedButtonIndex: 1, animated: false)
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }

    // cancel button presses are cancelled errors
    func test2() {
        let ex = expectation(withDescription: "")

        let sheet = UIActionSheet()
        sheet.addButton(withTitle: "0")
        sheet.addButton(withTitle: "1")
        sheet.cancelButtonIndex = sheet.addButton(withTitle: "2")
        sheet.promise(in: rootvc.view).error(policy: .allErrors) { err in
            guard let err = err as? UIActionSheet.Error else { return XCTFail() }
            XCTAssertTrue(err == UIActionSheet.Error.Cancelled)
            XCTAssertTrue(err.cancelled)
            ex.fulfill()
        }
        after(0.5).then {
            sheet.dismiss(withClickedButtonIndex: 2, animated: false)
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }

    // single button UIActionSheets don't get considered cancelled
    func test3() {
        let ex = expectation(withDescription: "")

        let sheet = UIActionSheet()
        sheet.addButton(withTitle: "0")
        sheet.promise(in: rootvc.view).then { _ in
            ex.fulfill()
        }
        after(0.5).then {
            sheet.dismiss(withClickedButtonIndex: 0, animated: false)
        }
        waitForExpectations(withTimeout: 3, handler: nil)
    }

    // single button UIActionSheets don't get considered cancelled unless the cancelIndex is set
    func test4() {
        let ex = expectation(withDescription: "")

        let sheet = UIActionSheet()
        sheet.cancelButtonIndex = sheet.addButton(withTitle: "0")
        sheet.promise(in: rootvc.view).error(policy: .allErrors) { _ in
            ex.fulfill()
        }
        after(0.5).then {
            sheet.dismiss(withClickedButtonIndex: 0, animated: false)
        }
        waitForExpectations(withTimeout: 3, handler: nil)
    }
}
