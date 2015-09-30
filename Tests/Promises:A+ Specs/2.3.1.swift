import PromiseKit
import XCTest

class Test231: XCTestCase {

    // 2.3.1: If `promise` and `x` refer to the same object, reject
    // `promise` with a `TypeError' as the reason.

    func test1() {
        let ex = expectationWithDescription("")

        // specify: via return from a fulfilled promise

        let promise1 = after(0.1)
        let promise2 = promise1.then { promise1 }

        promise2.error { err in
            XCTAssertEqual(err, PromiseKit.Error.ReturnedSelf)
            ex.fulfill()
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test2() {
        let ex = expectationWithDescription("")

        // specify: via return from a rejected promise

        let promise1 = Promise<Void>(error: Error.Dummy)
        let promise2 = promise1.recover { _ in promise1 }

        promise2.error { err in
            XCTAssertEqual(err, PromiseKit.Error.ReturnedSelf)
            ex.fulfill()
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
