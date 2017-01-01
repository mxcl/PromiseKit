import PromiseKit
import XCTest

class RegressionTests: XCTestCase {
    func testReturningPreviousPromiseWorks() {

        // regression test because we were doing this wrong
        // in our A+ tests implementation for spec: 2.3.1

        do {
            let promise1 = Promise()
            let promise2 = promise1.then(on: nil) { promise1 }
            promise2.catch(on: nil) { _ in XCTFail() }
        }
        do {
            enum Error: Swift.Error { case dummy }

            let promise1 = Promise<Void>(error: Error.dummy)
            let promise2 = promise1.recover(on: nil) { _ in promise1 }
            promise2.catch(on: nil) { err in
                if case PMKError.returnedSelf = err {
                    XCTFail()
                }
            }
        }
    }
}
