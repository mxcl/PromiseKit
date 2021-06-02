import PromiseKit
import XCTest

class AfterTests: XCTestCase {
    func testZero() {
        let ex2 = expectation(description: "")
        after(seconds: 0).done(ex2.fulfill)
        waitForExpectations(timeout: 5, handler: nil)

        let ex3 = expectation(description: "")
        after(.seconds(0)).done(ex3.fulfill)
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testNegative() {
        let ex2 = expectation(description: "")
        after(seconds: -1).done(ex2.fulfill)
        waitForExpectations(timeout: 5, handler: nil)

        let ex3 = expectation(description: "")
        after(.seconds(-1)).done(ex3.fulfill)
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testPositive() {
        let ex2 = expectation(description: "")
        after(seconds: 1).done(ex2.fulfill)
        waitForExpectations(timeout: 5, handler: nil)

        let ex3 = expectation(description: "")
        after(.seconds(1)).done(ex3.fulfill)
        waitForExpectations(timeout: 5, handler: nil)
    }
}
