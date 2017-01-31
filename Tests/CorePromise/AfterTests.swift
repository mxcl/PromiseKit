import PromiseKit
import XCTest

class AfterTests: XCTestCase {
    func testZero() {
        wait { ex in
            after(interval: 0).then(execute: ex.fulfill)
        }
    }

    func testNegative() {
        wait { ex in
            after(interval: -1).then(execute: ex.fulfill)
        }
    }

    func testPositive() {
        wait { ex in
            after(interval: 1).then(execute: ex.fulfill)
        }
    }
}
