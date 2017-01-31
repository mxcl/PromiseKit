import PromiseKit
import XCTest

private enum E: Error { case dummy }

class RegressionTests: XCTestCase {
    func testReturningPreviousPromiseWorks() {

        // regression test because we were doing this wrong
        // in our A+ tests implementation for spec: 2.3.1

        wait { ex in
            let promise1 = Promise()
            let promise2 = promise1.then{ promise1 }
            promise2.then(execute: ex.fulfill)
        }

        wait { ex in
            let promise1 = Promise<Void>(error: E.dummy)
            let promise2 = promise1.recover{ _ in promise1 }
            promise2.catch { e in
                if case E.dummy = e { ex.fulfill() }
            }
        }
    }
}
