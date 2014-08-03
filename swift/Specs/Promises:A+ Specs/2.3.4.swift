import PromiseKit
import XCTest


class Test234: XCTestCase {

    // 2.3.4: If `x` is not an object or function, fulfill `promise` with `x`

    func test234() {
        suiteFulfilled(1) { (promise1, exes, memo)->Void in
            let promise2 = promise1.then { (a: Int)->Int in
                return 1
            }

            promise2.then { (a: Int)->Void in
                XCTAssertEqual(a, 1)
                exes[0].fulfill()
            }
        }

        suiteRejected(1) { (promise1, exes, memo)->Void in
            let promise2 = promise1.catch { (a: NSError)->Int in
                return 1
            }

            promise2.then { (a: Int)->Void in
                XCTAssertEqual(a, 1)
                exes[0].fulfill()
            }
        }
    }
}
