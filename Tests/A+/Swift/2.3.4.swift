import PromiseKit
import XCTest


class Test234: XCTestCase {
    func test() {
        describe("2.3.4: If `x` is not an object or function, fulfill `promise` with `x`") {
            testFulfilled { promise, exception, _ in
                promise.map { value -> UInt32 in
                    return 1
                }.done { value in
                    XCTAssertEqual(value, 1)
                    exception.fulfill()
                }.silenceWarning()
            }
            testRejected { promise, expectation, _ in
                promise.recover { _ -> Promise<UInt32> in
                    return .value(UInt32(1))
                }.done { value in
                    XCTAssertEqual(value, 1)
                    expectation.fulfill()
                }.silenceWarning()
            }
        }
    }
}
