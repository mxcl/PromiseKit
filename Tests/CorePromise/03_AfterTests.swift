import PromiseKit
import XCTest

class AfterTests: XCTestCase {
    func testZero() {
        let ex1 = expectation(description: "")
        after(interval: 0).then(execute: ex1.fulfill)
        waitForExpectations(timeout: 2, handler: nil)

        let ex2 = expectation(description: "")
        after(seconds: 0).then(execute: ex2.fulfill)
        waitForExpectations(timeout: 2, handler: nil)

        let ex3 = expectation(description: "")
        after(interval: .seconds(0)).then(execute: ex3.fulfill)
        waitForExpectations(timeout: 2, handler: nil)

        let ex4 = expectation(description: "")
        __PMKAfter(0).then{ _ in ex4.fulfill() }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testNegative() {
        let ex1 = expectation(description: "")
        after(interval: -1).then(execute: ex1.fulfill)
        waitForExpectations(timeout: 2, handler: nil)

        let ex2 = expectation(description: "")
        after(seconds: -1).then(execute: ex2.fulfill)
        waitForExpectations(timeout: 2, handler: nil)

        let ex3 = expectation(description: "")
        after(interval: .seconds(-1)).then(execute: ex3.fulfill)
        waitForExpectations(timeout: 2, handler: nil)

        let ex4 = expectation(description: "")
        __PMKAfter(-1).then{ _ in ex4.fulfill() }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testPositive() {
        let ex1 = expectation(description: "")
        after(interval: 1).then(execute: ex1.fulfill)
        waitForExpectations(timeout: 2, handler: nil)

        let ex2 = expectation(description: "")
        after(seconds: 1).then(execute: ex2.fulfill)
        waitForExpectations(timeout: 2, handler: nil)

        let ex3 = expectation(description: "")
        after(interval: .seconds(1)).then(execute: ex3.fulfill)
        waitForExpectations(timeout: 2, handler: nil)

        let ex4 = expectation(description: "")
        __PMKAfter(1).then{ _ in ex4.fulfill() }
        waitForExpectations(timeout: 2, handler: nil)
    }
}
