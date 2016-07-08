import PromiseKit
import XCTest


class Test234: XCTestCase {

    // 2.3.4: If `x` is not an object or function, fulfill `promise` with `x`

    func test1() {
        testFulfilled { promise, exes, memo in
            promise.then { value -> Int in
                return 1
            }.then { value -> Void in
                XCTAssertEqual(value, 1)
                exes[0].fulfill()
            }
        }
    }

    func test2() {
        testRejected { promise, exes, memo in
            promise.recover { _ -> Int in
                return 1
            }.then { value -> Void in
                XCTAssertEqual(value, 1)
                exes[0].fulfill()
            }
        }
    }
}
