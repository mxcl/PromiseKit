import PromiseKit
import XCTest

class AfterTestCase_Swift: XCTestCase {
    func __test(_ duration: TimeInterval) {
        let ex = expectation(withDescription: "")
        var foo = false
        after(duration).then { _ -> Void in
            ex.fulfill()
            foo = true
        }
        XCTAssertFalse(foo)
        waitForExpectations(withTimeout: 2, handler: nil)
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
