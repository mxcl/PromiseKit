import PromiseKit
import XCTest

class AfterTests: XCTestCase {
    func testZero() {
        let ex2 = expectation(description: "")
        after(seconds: 0).done(ex2.fulfill)
        waitForExpectations(timeout: 2, handler: nil)

        let ex3 = expectation(description: "")
        after(.seconds(0)).done(ex3.fulfill)
        waitForExpectations(timeout: 2, handler: nil)

    #if !SWIFT_PACKAGE
        let ex4 = expectation(description: "")
        __PMKAfter(0).done{ _ in ex4.fulfill() }.silenceWarning()
        waitForExpectations(timeout: 2, handler: nil)
    #endif
    }

    func testNegative() {
        let ex2 = expectation(description: "")
        after(seconds: -1).done(ex2.fulfill)
        waitForExpectations(timeout: 2, handler: nil)

        let ex3 = expectation(description: "")
        after(.seconds(-1)).done(ex3.fulfill)
        waitForExpectations(timeout: 2, handler: nil)

    #if !SWIFT_PACKAGE
        let ex4 = expectation(description: "")
        __PMKAfter(-1).done{ _ in ex4.fulfill() }.silenceWarning()
        waitForExpectations(timeout: 2, handler: nil)
    #endif
    }

    func testPositive() {
        let ex2 = expectation(description: "")
        after(seconds: 1).done(ex2.fulfill)
        waitForExpectations(timeout: 2, handler: nil)

        let ex3 = expectation(description: "")
        after(.seconds(1)).done(ex3.fulfill)
        waitForExpectations(timeout: 2, handler: nil)

    #if !SWIFT_PACKAGE
        let ex4 = expectation(description: "")
        __PMKAfter(1).done{ _ in ex4.fulfill() }.silenceWarning()
        waitForExpectations(timeout: 2, handler: nil)
    #endif
    }
}
