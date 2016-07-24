import PromiseKit
import XCTest

class AfterTests: XCTestCase {
    func testZero() {
        let ex1 = expectation(description: "")
        after(interval: 0).then(execute: ex1.fulfill)
        waitForExpectations(timeout: 2, handler: nil)

        let ex2 = expectation(description: "")
        __PMKAfter(0).then{ _ in ex2.fulfill() }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testNegative() {
        let ex1 = expectation(description: "")
        after(interval: -1).then(execute: ex1.fulfill)
        waitForExpectations(timeout: 2, handler: nil)

        let ex2 = expectation(description: "")
        __PMKAfter(-1).then{ _ in ex2.fulfill() }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testPositive() {
        let ex1 = expectation(description: "")
        after(interval: 1).then(execute: ex1.fulfill)
        waitForExpectations(timeout: 2, handler: nil)

        let ex2 = expectation(description: "")
        __PMKAfter(1).then{ _ in ex2.fulfill() }
        waitForExpectations(timeout: 2, handler: nil)
    }
}
