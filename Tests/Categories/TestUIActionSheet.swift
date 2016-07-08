import PromiseKit
import UIKit
import XCTest

class Test_UIActionSheet_Swift: UIKitTestCase {
    // fulfills with buttonIndex
    func test1() {
        let ex = expectation(description: "")

        let sheet = UIActionSheet()
        sheet.addButton(withTitle: "0")
        sheet.addButton(withTitle: "1")
        sheet.cancelButtonIndex = sheet.addButton(withTitle: "2")
        sheet.promise(in: rootvc.view).then { x -> Void in
            XCTAssertEqual(x, 1)
            ex.fulfill()
        }
        after(interval: 0.1).then {
            sheet.dismiss(withClickedButtonIndex: 1, animated: false)
        }
        waitForExpectations(timeout: 3)
    }

    // cancel button presses are cancelled errors
    func test2() {
        let ex = expectation(description: "")

        let sheet = UIActionSheet()
        sheet.addButton(withTitle: "0")
        sheet.addButton(withTitle: "1")
        sheet.cancelButtonIndex = sheet.addButton(withTitle: "2")
        sheet.promise(in: rootvc.view).catch(policy: .allErrors) { err in
            guard let err = err as? UIActionSheet.Error else { return XCTFail() }
            XCTAssertTrue(err == UIActionSheet.Error.cancelled)
            XCTAssertTrue(err.isCancelled)
            ex.fulfill()
        }
        after(interval: 0.1).then {
            sheet.dismiss(withClickedButtonIndex: 2, animated: false)
        }
        waitForExpectations(timeout: 3)
    }

    // single button UIActionSheets don't get considered cancelled
    func test3() {
        let ex = expectation(description: "")

        let sheet = UIActionSheet()
        sheet.addButton(withTitle: "0")
        sheet.promise(in: rootvc.view).then { _ in
            ex.fulfill()
        }
        after(interval: 0.1).then {
            sheet.dismiss(withClickedButtonIndex: 0, animated: false)
        }
        waitForExpectations(timeout: 3)
    }

    // single button UIActionSheets don't get considered cancelled unless the cancelIndex is set
    func test4() {
        let ex = expectation(description: "")

        let sheet = UIActionSheet()
        sheet.cancelButtonIndex = sheet.addButton(withTitle: "0")
        sheet.promise(in: rootvc.view).catch(policy: .allErrors) { _ in
            ex.fulfill()
        }
        after(interval: 0.1).then {
            sheet.dismiss(withClickedButtonIndex: 0, animated: false)
        }
        waitForExpectations(timeout: 3)
    }
}
