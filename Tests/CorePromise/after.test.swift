import PromiseKit
import XCTest

class AfterTestCase_Swift: XCTestCase {
    func __test(duration: NSTimeInterval) {
        let ex = expectationWithDescription("")
        var foo = false
        after(duration).then { _ -> Void in
            ex.fulfill()
            foo = true
        }
        XCTAssertFalse(foo)
        waitForExpectationsWithTimeout(2, handler: nil)
    }

    func testZero() {
        __test(0)
    }

    func testNegative() {
        __test(-1)
    }

    func testPositive() {
        __test(1)
    }
}
