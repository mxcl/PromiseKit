import PromiseKit
import XCTest


class Test234: XCTestCase {
    func test() {
        describe("2.3.4: If `x` is not an object or function, fulfill `promise` with `x`") {
            testFulfilled { promise, exception, _ in
                promise.then { value -> UInt32 in
                    return 1
                }.then { value -> Void in
                    XCTAssertEqual(value, 1)
                    exception.fulfill()
                }
            }
            testRejected { promise, expectation, _ in
                promise.recover { _ -> UInt32 in
                    return 1
                }.then { value -> Void in
                    XCTAssertEqual(value, 1)
                    expectation.fulfill()
                }
            }
        }
    }
}
